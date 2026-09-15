import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';
import '../../core/network/sdk_provider.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/fcm_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import '../auth/app_lock_screen.dart';
import '../auth/login_screen.dart';
import 'main_tab_screen.dart';
import 'maintenance_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final Duration minDisplayDuration;

  const SplashScreen({
    super.key,
    this.minDisplayDuration = const Duration(milliseconds: 800),
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    // 1. Restore or initialize the SDK so runtime Firebase config is available.
    bool isAuthenticated = false;
    try {
      final sdkNotifier = ref.read(hubsightSdkProvider.notifier);
      final restored = await sdkNotifier.restoreFromStorage();

      if (restored) {
        final sdk = ref.read(hubsightSdkProvider);
        if (sdk != null) {
          isAuthenticated = await sdk.auth.isAuthenticated;
          if (isAuthenticated) {
            try {
              final profile = await sdk.auth.getProfile();
              ref.read(appThemeModeProvider.notifier).syncFromProfile(profile.theme);
            } catch (_) {}
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
    } catch (e) {
      debugPrint('SDK session initialization error: $e');
    }

    // 2. Initialize FCM from google-services.json embedded in the active config.
    try {
      await ref.read(fcmServiceProvider).initialize();
    } catch (e) {
      debugPrint('FCM initialization error: $e');
    }

    // 3. Guarantee minimal smooth display duration
    final elapsed = DateTime.now().difference(startTime);
    final remaining = widget.minDisplayDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (!mounted) return;

    // 4. Check for system maintenance
    final maintenanceEx = ref.read(maintenanceStateProvider);
    if (maintenanceEx != null) {
      _navigateTo(const MaintenanceScreen());
      return;
    }

    // 5. Determine target route (no MainTabScreen flashing if App Lock is enabled)
    if (isAuthenticated) {
      final bio = ref.read(biometricServiceProvider);
      if (bio.isAppLockEnabled) {
        _navigateTo(
          AppLockScreen(
            onUnlocked: () {
              bio.clearBackgroundTime();
            },
          ),
        );
        return;
      }
      _navigateTo(const MainTabScreen());
    } else {
      _navigateTo(const LoginScreen());
    }
  }

  void _navigateTo(Widget target) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => target,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: HubSightColors.bgDark,
      body: Stack(
        children: [
          // Ambient central glow
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    HubSightColors.primary.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Central brand identity
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Icon Squircle
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFEA580C),
                            Color(0xFFFB923C),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEA580C).withValues(alpha: 0.42),
                            blurRadius: 28,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: Image.asset(
                          'assets/images/hubsight-mark.png',
                          key: const Key('hubsight-brand-mark'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // App Title
                    const Text(
                      'HubSight',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF4F4F5),
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle / Tagline
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        l10n?.splashTagline ?? 'Giám sát & Quản trị Camera Thông minh',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFA1A1AA),
                          letterSpacing: 0.2,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom status & enterprise footer
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: HubSightColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n?.splashInitializing ?? 'Đang khởi tạo môi trường bảo mật...',
                        style: const TextStyle(
                          color: Color(0xFF71717A),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n?.splashSubtitle ?? 'Nền tảng Camera An ninh & AI Doanh nghiệp',
                    style: const TextStyle(
                      color: Color(0xFF52525B),
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
