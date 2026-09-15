import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/sdk_provider.dart';
import 'firebase_config_parser.dart';

const androidNotificationChannel = AndroidNotificationChannel(
  'hubsight_alerts',
  'HubSight Alerts',
  description: 'Camera and security alerts',
  importance: Importance.high,
);

const _pendingNotificationTapKey = 'hubsight_pending_notification_tap';
const _pushSessionEnabledKey = 'hubsight_push_session_enabled';
final _localNotificationResponseController =
    StreamController<String>.broadcast();

/// Registers the top-level FCM handler before Flutter creates the widget tree.
void registerFcmBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

/// Handles data-only FCM messages when Android has backgrounded or terminated
/// the app. Firebase options are persisted because this isolate cannot access
/// the active Riverpod/SDK instance.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    if (preferences.getBool(_pushSessionEnabledKey) != true) return;
    final encodedOptions = preferences.getString(
      storedAndroidFirebaseOptionsKey,
    );
    if (encodedOptions == null || encodedOptions.isEmpty) return;

    final options = decodeFirebaseOptions(encodedOptions);
    await _ensureFirebaseInitialized(options);

    final notifications = FlutterLocalNotificationsPlugin();
    await _initializeLocalNotifications(notifications);
    if (message.notification == null) {
      await _showLocalNotification(notifications, message);
    }
  } catch (error) {
    debugPrint('FCM background handler failed: $error');
  }
}

@pragma('vm:entry-point')
Future<void> localNotificationBackgroundResponse(
  NotificationResponse response,
) async {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString(_pendingNotificationTapKey, payload);
}

void _handleLocalNotificationResponse(NotificationResponse response) {
  final payload = response.payload;
  if (payload != null && payload.isNotEmpty) {
    _localNotificationResponseController.add(payload);
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  final service = FcmService(ref: ref);
  ref.onDispose(service.dispose);
  return service;
});

class PushNotificationPayload {
  const PushNotificationPayload({
    required this.data,
    this.messageId,
    this.title,
    this.body,
  });

  factory PushNotificationPayload.fromRemoteMessage(RemoteMessage message) {
    return PushNotificationPayload(
      data: Map<String, String>.unmodifiable(message.data),
      messageId: message.messageId,
      title: message.notification?.title ?? message.data['title'],
      body: message.notification?.body ?? message.data['body'],
    );
  }

  factory PushNotificationPayload.decode(String encoded) {
    final value = jsonDecode(encoded);
    if (value is! Map) {
      throw const FormatException('Invalid notification payload.');
    }
    final rawData = value['data'];
    final data = <String, String>{};
    if (rawData is Map) {
      for (final entry in rawData.entries) {
        data[entry.key.toString()] = entry.value.toString();
      }
    }
    return PushNotificationPayload(
      data: Map<String, String>.unmodifiable(data),
      messageId: value['messageId']?.toString(),
      title: value['title']?.toString(),
      body: value['body']?.toString(),
    );
  }

  final Map<String, String> data;
  final String? messageId;
  final String? title;
  final String? body;

  String? get id => data['id'] ?? messageId;
  String? get cameraId => data['camera_id'];
  String? get url => data['url'];

  String encode() {
    return jsonEncode(<String, Object?>{
      'data': data,
      'messageId': messageId,
      'title': title,
      'body': body,
    });
  }
}

class FcmService {
  FcmService({required Ref ref}) : _ref = ref;

  final Ref _ref;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final _pushMessageController =
      StreamController<PushNotificationPayload>.broadcast();
  final _notificationClickController =
      StreamController<PushNotificationPayload>.broadcast();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  StreamSubscription<String>? _localResponseSubscription;
  Future<bool>? _initialization;
  String? _configIdentity;
  String? _fcmToken;
  PushNotificationPayload? _pendingNotificationTap;
  bool _isInitialized = false;
  bool _registrationSuspended = false;
  bool _didReadLaunchDetails = false;
  bool _isDisposed = false;

  Stream<PushNotificationPayload> get onPushReceived =>
      _pushMessageController.stream;
  Stream<PushNotificationPayload> get onNotificationTapped =>
      _notificationClickController.stream;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// Initializes Android FCM from google-services.json embedded in the active
  /// `.hscfg` profile. Calling this again switches Firebase projects safely.
  Future<bool> initialize({bool requestPermission = true}) {
    final inProgress = _initialization;
    if (inProgress != null) return inProgress;

    final operation = _initialize(requestPermission: requestPermission);
    _initialization = operation;
    return operation.whenComplete(() {
      if (identical(_initialization, operation)) _initialization = null;
    });
  }

  Future<bool> _initialize({required bool requestPermission}) async {
    if (_isDisposed || !Platform.isAndroid) return false;

    final sdk = _ref.read(hubsightSdkProvider);
    final googleServicesJson = sdk?.config.googleServicesJson;
    if (googleServicesJson == null || googleServicesJson.trim().isEmpty) {
      await _disableForMissingConfig();
      debugPrint(
        'FCM is disabled: active .hscfg profile has no google-services.json.',
      );
      return false;
    }

    try {
      final options = parseAndroidFirebaseOptions(googleServicesJson);
      final identity = encodeFirebaseOptions(options);
      if (_isInitialized && identity == _configIdentity) {
        if (requestPermission) await _requestNotificationPermission();
        await syncTokenWithBackend();
        return true;
      }

      if (_isInitialized && identity != _configIdentity) {
        await _deleteCurrentFirebaseToken();
      }
      await _cancelSubscriptions();
      _fcmToken = null;
      _pendingNotificationTap = null;
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_pushSessionEnabledKey, false);

      await _ensureFirebaseInitialized(options);
      await preferences.setString(
        storedAndroidFirebaseOptionsKey,
        identity,
      );
      await _initializeLocalNotifications(_localNotifications);
      await _createAndroidChannel();

      _localResponseSubscription =
          _localNotificationResponseController.stream.listen(
        _handleEncodedNotificationTap,
      );

      if (requestPermission) await _requestNotificationPermission();
      _registrationSuspended = false;

      final messaging = FirebaseMessaging.instance;
      _messageSubscription = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );
      _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _publishNotificationTap(
          PushNotificationPayload.fromRemoteMessage(message),
        ),
      );
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        debugPrint('FCM token refreshed (${_maskedToken(token)}).');
        unawaited(_registerTokenWithBackend(token));
      });

      try {
        _fcmToken = await messaging.getToken();
        if (_fcmToken != null) {
          debugPrint('FCM token acquired (${_maskedToken(_fcmToken!)}).');
          await _registerTokenWithBackend(_fcmToken!);
        }
      } catch (error) {
        debugPrint('FCM token is not available yet: $error');
      }

      await _restorePendingLocalNotificationTap();
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _publishNotificationTap(
          PushNotificationPayload.fromRemoteMessage(initialMessage),
        );
      }

      _configIdentity = identity;
      _isInitialized = true;
      debugPrint('FCM initialized for Firebase project ${options.projectId}.');
      return true;
    } catch (error, stackTrace) {
      await _disableForMissingConfig(deleteFirebaseApp: true);
      debugPrint('FCM initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final sdk = _ref.read(hubsightSdkProvider);
    if (_registrationSuspended ||
        sdk == null ||
        !await sdk.auth.isAuthenticated) {
      return;
    }
    final payload = PushNotificationPayload.fromRemoteMessage(message);
    _pushMessageController.add(payload);
    try {
      await _showLocalNotification(_localNotifications, message);
    } catch (error) {
      debugPrint('Could not display foreground notification: $error');
    }
  }

  Future<void> _requestNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint(
      'Notification permission status: ${settings.authorizationStatus}.',
    );
  }

  Future<void> _createAndroidChannel() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
  }

  Future<void> _restorePendingLocalNotificationTap() async {
    if (!_didReadLaunchDetails) {
      _didReadLaunchDetails = true;
      final launchDetails =
          await _localNotifications.getNotificationAppLaunchDetails();
      final launchPayload = launchDetails?.notificationResponse?.payload;
      if (launchDetails?.didNotificationLaunchApp == true &&
          launchPayload != null &&
          launchPayload.isNotEmpty) {
        _handleEncodedNotificationTap(launchPayload);
      }
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final storedPayload = preferences.getString(_pendingNotificationTapKey);
    if (storedPayload != null && storedPayload.isNotEmpty) {
      await preferences.remove(_pendingNotificationTapKey);
      _handleEncodedNotificationTap(storedPayload);
    }
  }

  void _handleEncodedNotificationTap(String encoded) {
    try {
      _publishNotificationTap(PushNotificationPayload.decode(encoded));
    } catch (error) {
      debugPrint('Ignoring malformed notification tap payload: $error');
    }
  }

  void _publishNotificationTap(PushNotificationPayload payload) {
    _pendingNotificationTap = payload;
    _notificationClickController.add(payload);
  }

  PushNotificationPayload? takePendingNotificationTap() {
    final pending = _pendingNotificationTap;
    _pendingNotificationTap = null;
    return pending;
  }

  /// Removes the current token from the old backend/Firebase project before
  /// activating another `.hscfg` profile.
  Future<void> prepareForConfigSwitch() async {
    if (!Platform.isAndroid) return;
    await unregisterTokenForLogout();
    await _cancelSubscriptions();
    await _deleteDefaultFirebaseApp();
    _fcmToken = null;
    _configIdentity = null;
    _pendingNotificationTap = null;
    _isInitialized = false;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(storedAndroidFirebaseOptionsKey);
    await preferences.remove(_pendingNotificationTapKey);
  }

  /// Stops notification delivery for the signed-out user while keeping the
  /// runtime Firebase configuration ready for a later login.
  Future<void> unregisterTokenForLogout() async {
    if (!Platform.isAndroid) return;
    _registrationSuspended = true;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_pushSessionEnabledKey, false);
    await preferences.remove(_pendingNotificationTapKey);
    _pendingNotificationTap = null;
    if (_isInitialized) await _localNotifications.cancelAll();

    final token = _fcmToken;
    final sdk = _ref.read(hubsightSdkProvider);
    if (token != null && sdk != null) {
      try {
        await sdk.fcm.unregisterPushToken(token);
      } catch (error) {
        debugPrint('Failed to unregister FCM token from backend: $error');
      }
    }
    await _deleteCurrentFirebaseToken();
    _fcmToken = null;
  }

  /// Re-syncs the current token after login or a session refresh.
  Future<void> syncTokenWithBackend() async {
    if (!_isInitialized) return;
    _registrationSuspended = false;
    String? token = _fcmToken;
    if (token == null) {
      try {
        token = await FirebaseMessaging.instance.getToken();
        _fcmToken = token;
      } catch (error) {
        debugPrint('Could not refresh FCM token after login: $error');
      }
    }
    if (token != null) await _registerTokenWithBackend(token);
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      if (_registrationSuspended) return;
      final sdk = _ref.read(hubsightSdkProvider);
      if (sdk == null || !await sdk.auth.isAuthenticated) return;
      await sdk.fcm.registerPushToken(token);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_pushSessionEnabledKey, true);
      debugPrint('FCM token registered with HubSight backend.');
    } catch (error) {
      debugPrint('Failed to register FCM token with backend: $error');
    }
  }

  Future<void> _deleteCurrentFirebaseToken() async {
    if (!_isInitialized) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (error) {
      debugPrint('Could not delete current Firebase token: $error');
    }
  }

  Future<void> _disableForMissingConfig(
      {bool deleteFirebaseApp = false}) async {
    await _cancelSubscriptions();
    _fcmToken = null;
    _configIdentity = null;
    _pendingNotificationTap = null;
    _isInitialized = false;
    _registrationSuspended = true;
    if (deleteFirebaseApp) await _deleteDefaultFirebaseApp();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_pushSessionEnabledKey, false);
    await preferences.remove(storedAndroidFirebaseOptionsKey);
    await preferences.remove(_pendingNotificationTapKey);
  }

  Future<void> _cancelSubscriptions() async {
    await _tokenRefreshSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _messageOpenedSubscription?.cancel();
    await _localResponseSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _messageSubscription = null;
    _messageOpenedSubscription = null;
    _localResponseSubscription = null;
  }

  void dispose() {
    _isDisposed = true;
    unawaited(_cancelSubscriptions());
    unawaited(_pushMessageController.close());
    unawaited(_notificationClickController.close());
  }
}

Future<FirebaseApp> _ensureFirebaseInitialized(FirebaseOptions options) async {
  FirebaseApp? current;
  try {
    current = Firebase.app();
  } catch (_) {
    current = null;
  }

  if (current != null) {
    if (firebaseOptionsMatch(current.options, options)) return current;
    await current.delete();
  }
  return Firebase.initializeApp(options: options);
}

Future<void> _deleteDefaultFirebaseApp() async {
  try {
    final app = Firebase.app();
    await app.delete();
  } catch (_) {
    // There is no default Firebase app to delete.
  }
}

Future<void> _initializeLocalNotifications(
  FlutterLocalNotificationsPlugin notifications,
) async {
  await notifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
    ),
    onDidReceiveNotificationResponse: _handleLocalNotificationResponse,
    onDidReceiveBackgroundNotificationResponse:
        localNotificationBackgroundResponse,
  );
  await notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidNotificationChannel);
}

Future<void> _showLocalNotification(
  FlutterLocalNotificationsPlugin notifications,
  RemoteMessage message,
) async {
  final payload = PushNotificationPayload.fromRemoteMessage(message);
  final title = payload.title ?? 'HubSight';
  final body = payload.body;

  await notifications.show(
    id: _notificationId(payload),
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'hubsight_alerts',
        'HubSight Alerts',
        channelDescription: 'Camera and security alerts',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
        styleInformation: BigTextStyleInformation(body ?? ''),
      ),
    ),
    payload: payload.encode(),
  );
}

int _notificationId(PushNotificationPayload payload) {
  final source = payload.id ??
      '${payload.data['camera_id']}:${payload.data['created_at']}:${payload.title}';
  var hash = 0;
  for (final codeUnit in source.codeUnits) {
    hash = 0x1fffffff & (hash * 31 + codeUnit);
  }
  return hash;
}

String _maskedToken(String token) {
  if (token.length <= 8) return '********';
  return '${token.substring(0, 4)}…${token.substring(token.length - 4)}';
}
