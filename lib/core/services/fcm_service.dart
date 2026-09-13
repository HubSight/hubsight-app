import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/sdk_provider.dart';

/// Top-level background handler for FCM messages when app is in background or terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('FCM Background message received: ${message.messageId} - ${message.notification?.title}');
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref: ref);
});

class FcmService {
  final Ref _ref;
  bool _isInitialized = false;
  String? _fcmToken;

  final _pushMessageController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onPushReceived => _pushMessageController.stream;

  final _notificationClickController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onNotificationTapped => _notificationClickController.stream;

  FcmService({required Ref ref}) : _ref = ref;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// Initializes FCM service gracefully.
  /// If Firebase configuration (google-services.json / GoogleService-Info.plist)
  /// is not yet configured, it catches the error and logs a notice.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Firebase Core
      await Firebase.initializeApp();

      // 2. Set background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Request user notification permissions
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM permission authorization status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // 4. Retrieve FCM Token
        _fcmToken = await messaging.getToken();
        debugPrint('FCM Registration Token: $_fcmToken');

        if (_fcmToken != null) {
          await _registerTokenWithBackend(_fcmToken!);
        }

        // 5. Listen for Token refreshes
        messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          debugPrint('FCM Token Refreshed: $newToken');
          _registerTokenWithBackend(newToken);
        });

        // 6. Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('FCM Foreground message received: ${message.notification?.title} - ${message.notification?.body}');
          _pushMessageController.add(message);
        });

        // 7. Handle notification click when app is opened from background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('FCM Notification opened app: ${message.messageId}');
          _notificationClickController.add(message);
        });

        // 8. Check if application was launched by tapping a notification
        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          debugPrint('FCM App opened from cold start by notification: ${initialMessage.messageId}');
          _notificationClickController.add(initialMessage);
        }
      }

      _isInitialized = true;
      debugPrint('FCM Service initialized successfully.');
    } catch (e) {
      debugPrint('FCM Initialization Notice: Firebase configuration not yet active or failed: $e');
      debugPrint('FCM will activate automatically once Firebase platform config is added.');
    }
  }

  /// Sends device push token to backend via HubSight SDK
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final sdk = _ref.read(hubsightSdkProvider);
      if (sdk != null) {
        await sdk.fcm.registerPushToken(token);
        debugPrint('FCM token successfully registered with HubSight SDK.');
      }
    } catch (e) {
      debugPrint('Failed to register FCM token with backend: $e');
    }
  }

  /// Re-sync token with backend (e.g. after login or server URL change)
  Future<void> syncTokenWithBackend() async {
    if (_fcmToken != null) {
      await _registerTokenWithBackend(_fcmToken!);
    }
  }

  void dispose() {
    _pushMessageController.close();
    _notificationClickController.close();
  }
}

