import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/biometric_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/in_app_notification_service.dart';
import 'core/storage/storage_service.dart';
import 'features/auth/app_lock_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/config/server_config_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local preferences
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const HubSightApp(),
    ),
  );
}

class HubSightApp extends ConsumerStatefulWidget {
  const HubSightApp({super.key});

  @override
  ConsumerState<HubSightApp> createState() => _HubSightAppState();
}

class _HubSightAppState extends ConsumerState<HubSightApp> with WidgetsBindingObserver {
  bool _isLockScreenShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize in-app notification manager & FCM push notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inAppNotificationServiceProvider).attachNavigatorKey(rootNavigatorKey);
      ref.read(fcmServiceProvider).initialize();
      _checkInitialAppLock();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bio = ref.read(biometricServiceProvider);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      bio.recordBackgroundTime();
    } else if (state == AppLifecycleState.resumed) {
      _checkAppLock();
    }
  }

  void _checkInitialAppLock() {
    final bio = ref.read(biometricServiceProvider);
    final storage = ref.read(storageServiceProvider);
    if (storage.hasAuthToken() && bio.isAppLockEnabled) {
      _showAppLockModal();
    }
  }

  void _checkAppLock() {
    final bio = ref.read(biometricServiceProvider);
    final storage = ref.read(storageServiceProvider);
    if (storage.hasAuthToken() && bio.shouldRequireUnlock()) {
      _showAppLockModal();
    }
  }

  void _showAppLockModal() {
    if (_isLockScreenShowing) return;
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    _isLockScreenShowing = true;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, _, __) => AppLockScreen(
          onUnlocked: () {
            _isLockScreenShowing = false;
            ref.read(biometricServiceProvider).clearBackgroundTime();
            Navigator.pop(context);
          },
        ),
      ),
    ).then((_) {
      _isLockScreenShowing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);
    final hasServer = storage.hasServerUrl();

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'HubSight CCTV',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE85D10)),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('vi'),
      ],
      // Set to vi by default as per mockups, or let the system decide
      locale: const Locale('vi'),
      home: hasServer
          ? const LoginScreen()
          : const ServerConfigScreen(isInitialSetup: true),
      debugShowCheckedModeBanner: false,
    );
  }
}
