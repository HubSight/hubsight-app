import 'package:flutter/material.dart';
import 'package:cctv_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/sdk_provider.dart';
import 'core/services/biometric_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/in_app_notification_service.dart';
import 'core/storage/storage_service.dart';
import 'features/auth/app_lock_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/camera/playback_screen.dart';
import 'features/common/maintenance_screen.dart';
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

class _HubSightAppState extends ConsumerState<HubSightApp>
    with WidgetsBindingObserver {
  bool _isLockScreenShowing = false;
  bool _isCheckingInitialAuth = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize SDK, FCM push notifications & App lock
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref
          .read(inAppNotificationServiceProvider)
          .attachNavigatorKey(rootNavigatorKey);
      ref.read(fcmServiceProvider).initialize();

      // Restore SDK from storage if previously enrolled
      await _initializeSdkSession();
      _checkInitialAppLock();
    });
  }

  Future<void> _initializeSdkSession() async {
    final sdkNotifier = ref.read(hubsightSdkProvider.notifier);
    final restored = await sdkNotifier.restoreFromStorage();

    if (restored) {
      final sdk = ref.read(hubsightSdkProvider);
      if (sdk != null) {
        final isAuth = await sdk.auth.isAuthenticated;
        if (mounted) {
          setState(() {
            _isAuthenticated = isAuth;
            _isCheckingInitialAuth = false;
          });
          return;
        }
      }
    }

    if (mounted) {
      setState(() {
        _isAuthenticated = false;
        _isCheckingInitialAuth = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bio = ref.read(biometricServiceProvider);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      bio.recordBackgroundTime();
    } else if (state == AppLifecycleState.resumed) {
      _checkAppLock();
    }
  }

  void _checkInitialAppLock() {
    final bio = ref.read(biometricServiceProvider);
    if (_isAuthenticated && bio.isAppLockEnabled) {
      _showAppLockModal();
    }
  }

  void _checkAppLock() {
    final bio = ref.read(biometricServiceProvider);
    if (_isAuthenticated && bio.shouldRequireUnlock()) {
      _showAppLockModal();
    }
  }

  void _showAppLockModal() {
    if (_isLockScreenShowing) return;
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    _isLockScreenShowing = true;
    Navigator.of(context)
        .push(
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
    )
        .then((_) {
      _isLockScreenShowing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final maintenanceEx = ref.watch(maintenanceStateProvider);
    final sdk = ref.watch(hubsightSdkProvider);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'HubSight CCTV',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE85D10),
          primary: const Color(0xFFE85D10),
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      home: maintenanceEx != null
          ? const MaintenanceScreen()
          : _isCheckingInitialAuth
              ? const Scaffold(
                  backgroundColor: Color(0xFF0F172A),
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE85D10),
                    ),
                  ),
                )
              : sdk == null
                  ? const ServerConfigScreen(isInitialSetup: true)
                  : _isAuthenticated
                      ? const PlaybackScreen()
                      : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
