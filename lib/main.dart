import 'package:flutter/material.dart';
import 'package:hubsight_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';
import 'core/network/sdk_provider.dart';
import 'core/services/biometric_service.dart';
import 'core/services/fcm_service.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/app_lock_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/common/main_tab_screen.dart';
import 'features/common/maintenance_screen.dart';

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
        if (isAuth) {
          try {
            final profile = await sdk.auth.getProfile();
            ref.read(appThemeModeProvider.notifier).syncFromProfile(profile.theme);
          } catch (_) {}
        }
        if (mounted) {
          setState(() {
            _isAuthenticated = isAuth;
            _isCheckingInitialAuth = false;
          });
          return;
        }
      }
    } else {
      // Default initial server configuration for seamless out-of-the-box login
      const defaultServerUrl = 'https://cctv.quoctran.space';
      const defaultConfig = HubSightAppConfig(
        urls: HubSightUrls(
          gatewayUrl: defaultServerUrl,
          apiBaseUrl: '$defaultServerUrl/api',
          relayWsUrl: 'wss://cctv.quoctran.space/relay',
          webrtcBaseUrl: '$defaultServerUrl:8555',
        ),
        key: HubSightClientKey(
          clientId: 'hs_mob_default',
          clientSecret: '',
          clientName: 'HubSight Mobile',
        ),
        metadata: HubSightConfigMetadata(
          formatVersion: '1.0',
          configId: 'default_config',
          name: 'HubSight Server',
        ),
      );
      try {
        await sdkNotifier.initializeFromConfig(defaultConfig);
      } catch (e) {
        debugPrint('Default SDK config initialization error: $e');
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
    final appLocale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'HubSight',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: appLocale,
      home: maintenanceEx != null
          ? const MaintenanceScreen()
          : _isCheckingInitialAuth
              ? Scaffold(
                  backgroundColor: themeMode == ThemeMode.light
                      ? HubSightColors.bgLight
                      : HubSightColors.bgDark,
                  body: const Center(
                    child: CircularProgressIndicator(
                      color: HubSightColors.primary,
                    ),
                  ),
                )
              : _isAuthenticated
                  ? const MainTabScreen()
                  : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
