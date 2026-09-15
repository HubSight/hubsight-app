import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hubsight_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/sdk_provider.dart';
import 'core/services/biometric_service.dart';
import 'core/services/fcm_service.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/app_lock_screen.dart';
import 'features/common/maintenance_screen.dart';
import 'features/common/splash_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFcmBackgroundHandler();

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bio = ref.read(biometricServiceProvider);
    if (bio.isAuthenticating) return;

    if (state == AppLifecycleState.paused) {
      bio.recordBackgroundTime();
    } else if (state == AppLifecycleState.resumed) {
      final fcm = ref.read(fcmServiceProvider);
      if (fcm.isInitialized) {
        unawaited(fcm.syncTokenWithBackend());
      } else {
        unawaited(fcm.initialize(requestPermission: false));
      }
      _checkAppLock();
    }
  }

  void _checkAppLock() async {
    final bio = ref.read(biometricServiceProvider);
    if (!bio.isAppLockEnabled) return;
    if (!bio.shouldRequireUnlock()) return;

    final sdk = ref.read(hubsightSdkProvider);
    if (sdk == null) return;
    final isAuth = await sdk.auth.isAuthenticated;
    if (!isAuth) return;

    _showAppLockModal();
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

    ref.listen<bool>(remoteRevocationEventProvider, (previous, revoked) {
      if (revoked) {
        unawaited(ref.read(fcmServiceProvider).unregisterTokenForLogout());
      }
    });

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
          : const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
