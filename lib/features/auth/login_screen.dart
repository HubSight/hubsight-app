import 'package:flutter/material.dart';
import 'package:cctv_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';
import '../../core/localization/error_localizer.dart';
import '../../core/network/sdk_provider.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/fcm_service.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../camera/playback_screen.dart';
import '../config/server_config_screen.dart';
import 'change_password_dialog.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAppKeyError = false;
  bool _isBiometricLoading = false;
  String? _biometricLabel;

  // 2FA State
  bool _showTwoFactorModal = false;
  String? _preAuthToken;
  final _totpController = TextEditingController();
  final _recoveryCodeController = TextEditingController();
  bool _useRecoveryCode = false;
  bool _isVerifying2FA = false;
  String? _twoFactorError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRemoteRevocation();
      _initBiometricStatus();
      _checkQuickBiometricLogin();
    });
  }

  void _initBiometricStatus() async {
    final bio = ref.read(biometricServiceProvider);
    final label = await bio.getBiometricTypeLabel();
    final lastUser = bio.getLastUsername();
    if (mounted) {
      setState(() {
        _biometricLabel = label;
        if (lastUser != null && lastUser.isNotEmpty) {
          _usernameController.text = lastUser;
        }
      });
    }
  }

  void _checkRemoteRevocation() {
    final wasRevoked = ref.read(remoteRevocationEventProvider);
    if (wasRevoked) {
      ref.read(remoteRevocationEventProvider.notifier).reset();
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.remoteRevokedAlert)),
            ],
          ),
          backgroundColor: HubSightColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _checkQuickBiometricLogin() async {
    final bio = ref.read(biometricServiceProvider);
    final sdk = ref.read(hubsightSdkProvider);

    if (bio.isBiometricEnabled && sdk != null) {
      final isAuthed = await sdk.auth.isAuthenticated;
      if (isAuthed) {
        final success = await bio.authenticate(
          localizedReason: 'Đăng nhập nhanh bằng sinh trắc học vào HubSight',
        );
        if (success && mounted) {
          _navigateToHome();
        }
      }
    }
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (username.isEmpty || password.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isAppKeyError = false;
    });

    try {
      var sdk = ref.read(hubsightSdkProvider);
      if (sdk == null) {
        // Try restoring or initialize with default config
        final restored = await ref.read(hubsightSdkProvider.notifier).restoreFromStorage();
        if (!restored) {
          // If still null, route user to config setup
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ServerConfigScreen()),
            );
          }
          return;
        }
        sdk = ref.read(hubsightSdkProvider);
      }

      if (sdk == null) return;

      final result = await sdk.auth.login(
        username: username,
        password: password,
      );

      if (result.requires2FA) {
        // Show 2FA Verification Dialog
        setState(() {
          _preAuthToken = result.preAuthToken;
          _showTwoFactorModal = true;
          _isLoading = false;
        });
        return;
      }

      if (result.isSuccess) {
        await _onLoginSuccess(result, username: username, password: password);
      } else {
        setState(() {
          _errorMessage = result.message ?? l10n.errAuthInvalidCredentials;
        });
      }
    } catch (e) {
      if (mounted) {
        final isAppKeyErr = (e is HubSightAuthException) &&
            (e.code == HubSightErrorCode.appKeyRequired ||
                e.code == HubSightErrorCode.appKeyInvalidOrRevoked);
        setState(() {
          _errorMessage = AppErrorLocalizer.localize(e, l10n);
          _isAppKeyError = isAppKeyErr;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleVerify2FA() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _totpController.text.trim();
    final recoveryCode = _recoveryCodeController.text.trim();

    if (_preAuthToken == null) return;

    setState(() {
      _isVerifying2FA = true;
      _twoFactorError = null;
    });

    try {
      final sdk = ref.read(hubsightSdkProvider);
      if (sdk == null) return;

      final result = await sdk.auth.verify2FA(
        preAuthToken: _preAuthToken!,
        code: _useRecoveryCode ? '' : code,
        recoveryCode: _useRecoveryCode ? recoveryCode : null,
      );

      if (result.isSuccess) {
        setState(() => _showTwoFactorModal = false);
        await _onLoginSuccess(
          result,
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        setState(() {
          _twoFactorError = result.message ?? l10n.twoFactorFailed;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _twoFactorError = AppErrorLocalizer.localize(e, l10n);
        });
      }
    } finally {
      if (mounted) setState(() => _isVerifying2FA = false);
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (_isLoading || _isBiometricLoading) return;
    final l10n = AppLocalizations.of(context)!;
    final bio = ref.read(biometricServiceProvider);

    setState(() {
      _errorMessage = null;
      _isAppKeyError = false;
    });

    // 1. Check biometric hardware / enrollment
    final canCheck = await bio.canAuthenticateWithBiometrics();
    if (!canCheck) {
      final isSupported = await bio.canCheckBiometrics();
      if (mounted) {
        setState(() {
          _errorMessage = isSupported
              ? l10n.loginBiometricNotEnrolled
              : l10n.loginBiometricNotSupported;
        });
      }
      return;
    }

    // 2. Check if biometric credentials or active session exist
    final hasCreds = await bio.hasBiometricCredentials();
    var sdk = ref.read(hubsightSdkProvider);
    if (sdk == null) {
      await ref.read(hubsightSdkProvider.notifier).restoreFromStorage();
      sdk = ref.read(hubsightSdkProvider);
    }

    final isAuthed = sdk != null ? await sdk.auth.isAuthenticated : false;

    if (!hasCreds && !isAuthed) {
      if (mounted) {
        _showBiometricSetupNoticeDialog(l10n);
      }
      return;
    }

    // 3. Prompt native Face ID / Touch ID dialog
    final label = _biometricLabel ?? 'Sinh trắc học';
    final success = await bio.authenticate(
      localizedReason: '$label: ${l10n.loginBiometricPrompt}',
    );

    if (!success) {
      return;
    }

    // 4. Perform login with saved biometric credentials
    setState(() => _isBiometricLoading = true);
    try {
      if (hasCreds) {
        final creds = await bio.getBiometricCredentials();
        if (creds != null && sdk != null) {
          final result = await sdk.auth.login(
            username: creds['username']!,
            password: creds['password']!,
          );
          if (result.requires2FA) {
            if (mounted) {
              setState(() {
                _preAuthToken = result.preAuthToken;
                _showTwoFactorModal = true;
                _isBiometricLoading = false;
              });
            }
            return;
          }
          if (result.isSuccess) {
            await _onLoginSuccess(result);
            return;
          }
        }
      }

      // If active session token exists, verify profile or refresh
      if (sdk != null && await sdk.auth.isAuthenticated) {
        try {
          await sdk.auth.getProfile();
          if (mounted) _navigateToHome();
          return;
        } catch (_) {
          final refreshed = await sdk.auth.refreshToken();
          if (refreshed && mounted) {
            _navigateToHome();
            return;
          }
        }
      }

      if (mounted) {
        setState(() {
          _errorMessage = l10n.errSessionExpired;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppErrorLocalizer.localize(e, l10n);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isBiometricLoading = false);
      }
    }
  }

  void _showBiometricSetupNoticeDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HubSightColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: HubSightRadius.roundedCardLg,
          side: const BorderSide(color: HubSightColors.borderDark, width: 1.0),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: HubSightColors.primaryBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fingerprint_rounded, color: HubSightColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _biometricLabel ?? 'Sinh trắc học',
                style: const TextStyle(color: HubSightColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.loginBiometricNotConfigured,
          style: const TextStyle(color: HubSightColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: HubSightColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _getBiometricButtonText(AppLocalizations l10n) {
    if (_biometricLabel == 'Face ID') {
      return l10n.loginPasskeyBtnFaceId;
    } else if (_biometricLabel == 'Touch ID') {
      return l10n.loginPasskeyBtnTouchId;
    } else if (_biometricLabel == 'Vân tay') {
      return l10n.loginPasskeyBtnFingerprint;
    }
    return l10n.loginPasskeyBtn;
  }

  Future<void> _onLoginSuccess(
    AuthResult result, {
    String? username,
    String? password,
  }) async {
    final bio = ref.read(biometricServiceProvider);
    if (username != null && username.isNotEmpty) {
      await bio.saveLastUsername(username);
    }

    // 1. Check forced password change
    if (result.mustChangePassword && mounted) {
      final changed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ChangePasswordDialog(isForced: true),
      );
      if (changed != true) return;
    }

    // 2. Offer Biometric Setup if device supports it and not yet enrolled
    if (username != null && password != null && mounted) {
      final canBio = await bio.canAuthenticateWithBiometrics();
      final hasBio = await bio.hasBiometricCredentials();
      if (canBio && !hasBio && mounted) {
        final l10n = AppLocalizations.of(context)!;
        final shouldEnroll = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: HubSightColors.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: HubSightRadius.roundedCardLg,
              side: const BorderSide(color: HubSightColors.borderDark, width: 1.0),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: HubSightColors.primaryBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fingerprint_rounded, color: HubSightColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.biometricEnrollPromptTitle,
                    style: const TextStyle(color: HubSightColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              l10n.biometricEnrollPromptDesc,
              style: const TextStyle(color: HubSightColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.biometricEnrollLater, style: const TextStyle(color: HubSightColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HubSightColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: HubSightRadius.roundedXl),
                ),
                child: Text(l10n.biometricEnrollEnable),
              ),
            ],
          ),
        );

        if (shouldEnroll == true) {
          final authenticated = await bio.authenticate(
            localizedReason: l10n.loginBiometricPrompt,
          );
          if (authenticated) {
            await bio.saveBiometricCredentials(username: username, password: password);
          }
        }
      }
    }

    // 3. Register FCM Device Token
    final fcm = ref.read(fcmServiceProvider);
    final token = fcm.fcmToken;
    final sdk = ref.read(hubsightSdkProvider);
    if (token != null && sdk != null) {
      try {
        await sdk.fcm.registerPushToken(token);
      } catch (e) {
        debugPrint('FCM register token notice: $e');
      }
    }

    // 4. Connect Realtime Relay
    sdk?.relay.connect();

    // 5. Navigate
    if (mounted) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PlaybackScreen()),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _totpController.dispose();
    _recoveryCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sdk = ref.watch(hubsightSdkProvider);
    final appLocale = ref.watch(appLocaleProvider);

    return Scaffold(
      backgroundColor: HubSightColors.bgDark,
      body: Stack(
        children: [
          // Background subtle warm glow (matching WebApp ambient background)
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    HubSightColors.primary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Action Bar: Server Connection Status + Language Switcher
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Server URL Pill
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ServerConfigScreen(
                                    isInitialSetup: false),
                              ),
                            );
                          },
                          borderRadius: HubSightRadius.roundedCard,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: HubSightColors.cardDark,
                              borderRadius: HubSightRadius.roundedCard,
                              border: Border.all(
                                  color: HubSightColors.borderDark, width: 1.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: sdk != null
                                        ? HubSightColors.success
                                        : Colors.amber,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    sdk?.config.urls.gatewayUrl ??
                                        'Chưa cấu hình máy chủ',
                                    style: const TextStyle(
                                      color: HubSightColors.textSecondary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.tune_rounded,
                                    size: 13, color: HubSightColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Language Switcher Pill
                      InkWell(
                        onTap: () {
                          ref.read(appLocaleProvider.notifier).toggleLocale();
                        },
                        borderRadius: HubSightRadius.roundedCard,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: HubSightColors.cardDark,
                            borderRadius: HubSightRadius.roundedCard,
                            border: Border.all(
                                color: HubSightColors.borderDark, width: 1.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language_rounded,
                                  size: 14, color: HubSightColors.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                appLocale.languageCode.toUpperCase(),
                                style: const TextStyle(
                                  color: HubSightColors.textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Centered Card
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 24.0),
                          decoration: BoxDecoration(
                            color: HubSightColors.cardDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: HubSightColors.borderDark, width: 1.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.55),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Mobile Sheet Handle
                              Center(
                                child: Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: HubSightColors.borderDark,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Centered Brand Logo Box
                              Center(
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: HubSightColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: HubSightColors.primary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _showTwoFactorModal
                                        ? Icons.shield_outlined
                                        : Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Title
                              Text(
                                _showTwoFactorModal
                                    ? l10n.twoFactorTitle
                                    : 'HubSight',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: HubSightColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),

                              // Subtitle
                              Text(
                                _showTwoFactorModal
                                    ? l10n.twoFactorSubtitle
                                    : l10n.loginSubtitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: HubSightColors.textMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              // Error Banner
                              if ((!_showTwoFactorModal &&
                                      _errorMessage != null) ||
                                  (_showTwoFactorModal &&
                                      _twoFactorError != null)) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    color: HubSightColors.errorBg,
                                    borderRadius: HubSightRadius.roundedCard,
                                    border: Border.all(
                                        color: HubSightColors.errorBorder,
                                        width: 1.0),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(top: 2.0),
                                            child: Icon(
                                              Icons.error_outline,
                                              color: HubSightColors.error,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _showTwoFactorModal
                                                  ? _twoFactorError!
                                                  : _errorMessage!,
                                              style: const TextStyle(
                                                color: HubSightColors.errorText,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_isAppKeyError &&
                                          !_showTwoFactorModal) ...[
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 36,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const ServerConfigScreen(
                                                          isInitialSetup: false),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  HubSightColors.error,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: HubSightRadius
                                                    .roundedXl,
                                              ),
                                              elevation: 0,
                                            ),
                                            icon: const Icon(
                                                Icons.qr_code_scanner_rounded,
                                                size: 15),
                                            label: const Text(
                                              'Cấu hình máy chủ ngay',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],

                              // ── STEP 1: Credentials & Passkey ──
                              if (!_showTwoFactorModal) ...[
                                // Username Field
                                Text(
                                  l10n.usernameLabel.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: HubSightColors.textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _usernameController,
                                  style: const TextStyle(
                                      color: HubSightColors.textPrimary,
                                      fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: l10n.usernameHint,
                                    prefixIcon: const Icon(
                                        Icons.person_outline_rounded,
                                        size: 18),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Password Field
                                Text(
                                  l10n.passwordLabel.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: HubSightColors.textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(
                                      color: HubSightColors.textPrimary,
                                      fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: l10n.passwordHint,
                                    prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                        size: 18),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 18,
                                        color: HubSightColors.textMuted,
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Primary Submit Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: ElevatedButton(
                                    onPressed: (_isLoading ||
                                            _isBiometricLoading)
                                        ? null
                                        : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: HubSightColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            HubSightRadius.roundedXl,
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.2,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                l10n.loginButton,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 17,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // OR Divider
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Divider(
                                          color: HubSightColors.borderDark,
                                          thickness: 1),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Text(
                                        l10n.loginOrDivider.toUpperCase(),
                                        style: const TextStyle(
                                          color: HubSightColors.textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      child: Divider(
                                          color: HubSightColors.borderDark,
                                          thickness: 1),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Biometric / Passkey Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: OutlinedButton(
                                    onPressed: (_isLoading ||
                                            _isBiometricLoading)
                                        ? null
                                        : _handleBiometricLogin,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor:
                                          HubSightColors.surfaceDark,
                                      foregroundColor:
                                          HubSightColors.textPrimary,
                                      side: const BorderSide(
                                          color: HubSightColors.borderDark,
                                          width: 1.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            HubSightRadius.roundedXl,
                                      ),
                                    ),
                                    child: _isBiometricLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: HubSightColors.primary,
                                              strokeWidth: 2.2,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                _biometricLabel == 'Face ID'
                                                    ? Icons.face_rounded
                                                    : Icons
                                                        .fingerprint_rounded,
                                                color: HubSightColors.primary,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  _getBiometricButtonText(l10n),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: HubSightColors
                                                        .textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ] else ...[
                                // ── STEP 2: 2FA Inline Challenge ──
                                Text(
                                  (_useRecoveryCode
                                          ? l10n.recoveryCodeLabel
                                          : l10n.twoFactorCodeLabel)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: HubSightColors.textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (!_useRecoveryCode)
                                  TextField(
                                    controller: _totpController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    style: const TextStyle(
                                      color: HubSightColors.textPrimary,
                                      fontSize: 20,
                                      letterSpacing: 6,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      counterText: '',
                                      hintText: l10n.twoFactorCodeHint,
                                      hintStyle: const TextStyle(
                                        color: HubSightColors.textMuted,
                                        letterSpacing: 6,
                                      ),
                                    ),
                                  )
                                else
                                  TextField(
                                    controller: _recoveryCodeController,
                                    style: const TextStyle(
                                      color: HubSightColors.textPrimary,
                                      fontSize: 14,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      hintText: 'Nhập mã khôi phục 8-16 ký tự',
                                    ),
                                  ),
                                const SizedBox(height: 8),

                                // Toggle Recovery Code Link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _useRecoveryCode = !_useRecoveryCode;
                                        _twoFactorError = null;
                                      });
                                    },
                                    child: Text(
                                      _useRecoveryCode
                                          ? 'Sử dụng mã xác thực 6 số'
                                          : l10n.useRecoveryCode,
                                      style: const TextStyle(
                                        color: HubSightColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Verify Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: ElevatedButton(
                                    onPressed: _isVerifying2FA
                                        ? null
                                        : _handleVerify2FA,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: HubSightColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            HubSightRadius.roundedXl,
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isVerifying2FA
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.2,
                                            ),
                                          )
                                        : Text(
                                            l10n.verifyButton,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Back to Credentials
                                Center(
                                  child: TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _showTwoFactorModal = false;
                                        _totpController.clear();
                                        _recoveryCodeController.clear();
                                        _twoFactorError = null;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.arrow_back_rounded,
                                      size: 14,
                                      color: HubSightColors.textMuted,
                                    ),
                                    label: const Text(
                                      'Quay lại đăng nhập',
                                      style: TextStyle(
                                        color: HubSightColors.textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              // Footer inside Card
                              const SizedBox(height: 24),
                              const Divider(
                                  color: HubSightColors.borderDark,
                                  thickness: 1),
                              const SizedBox(height: 12),
                              Text(
                                l10n.footerVersion,
                                style: const TextStyle(
                                  color: HubSightColors.textMuted,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                l10n.footerCopyright,
                                style: const TextStyle(
                                  color: HubSightColors.textMuted,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
