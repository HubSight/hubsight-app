import 'package:flutter/material.dart';
import 'package:cctv_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';
import '../../core/localization/error_localizer.dart';
import '../../core/network/sdk_provider.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/fcm_service.dart';
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
      _checkQuickBiometricLogin();
    });
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
          backgroundColor: const Color(0xFFDC2626),
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
        await _onLoginSuccess(result);
      } else {
        setState(() {
          _errorMessage = result.message ?? l10n.errAuthInvalidCredentials;
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
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleVerify2FA() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _totpController.text.trim();
    final recoveryCode = _recoveryCodeController.text.trim();

    if (_preAuthToken == null) return;
    if (!_useRecoveryCode && (code.length != 6 || int.tryParse(code) == null)) {
      setState(() => _twoFactorError = l10n.twoFactorFailed);
      return;
    }
    if (_useRecoveryCode && recoveryCode.isEmpty) {
      setState(() => _twoFactorError = 'Vui lòng nhập mã khôi phục');
      return;
    }

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
        await _onLoginSuccess(result);
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

  Future<void> _onLoginSuccess(AuthResult result) async {
    // 1. Check forced password change
    if (result.mustChangePassword && mounted) {
      final changed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ChangePasswordDialog(isForced: true),
      );
      if (changed != true) return;
    }

    // 2. Register FCM Device Token
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

    // 3. Connect Realtime Relay
    sdk?.relay.connect();

    // 4. Navigate
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

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background Gradient decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE85D10).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar: Server status & Config button
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Server URL chip
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ServerConfigScreen(isInitialSetup: false),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: sdk != null ? const Color(0xFF10B981) : Colors.amber,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  sdk?.config.urls.gatewayUrl ?? 'Chưa cấu hình máy chủ',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.settings_outlined, size: 14, color: Color(0xFF94A3B8)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Brand Logo & Title
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE85D10),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE85D10).withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.videocam_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HubSight',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            l10n.loginSubtitle,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),

                  // Error Banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Username Field
                  Text(
                    l10n.usernameLabel,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: l10n.usernameHint,
                      hintStyle: const TextStyle(color: Color(0xFF475569)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF64748B), size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE85D10), width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Password Field
                  Text(
                    l10n.passwordLabel,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: l10n.passwordHint,
                      hintStyle: const TextStyle(color: Color(0xFF475569)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF64748B), size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF64748B),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE85D10), width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE85D10),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              l10n.loginButton,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Footer
                  Center(
                    child: Column(
                      children: [
                        Text(
                          l10n.footerVersion,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.footerCopyright,
                          style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2FA Challenge Modal Overlay
          if (_showTwoFactorModal) _buildTwoFactorModal(l10n),
        ],
      ),
    );
  }

  Widget _buildTwoFactorModal(AppLocalizations l10n) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE85D10).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.security, color: Color(0xFFE85D10), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.twoFactorTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.twoFactorSubtitle,
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_twoFactorError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Text(
                      _twoFactorError!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                ],

                if (!_useRecoveryCode) ...[
                  Text(
                    l10n.twoFactorCodeLabel,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _totpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      letterSpacing: 6,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: l10n.twoFactorCodeHint,
                      hintStyle: const TextStyle(color: Color(0xFF475569), letterSpacing: 6),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE85D10), width: 1.5),
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    l10n.recoveryCodeLabel,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _recoveryCodeController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Nhập mã khôi phục 8-16 ký tự',
                      hintStyle: const TextStyle(color: Color(0xFF475569)),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE85D10), width: 1.5),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Toggle Recovery Code mode
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
                      _useRecoveryCode ? 'Sử dụng mã xác thực 6 số' : l10n.useRecoveryCode,
                      style: const TextStyle(color: Color(0xFFE85D10), fontSize: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _showTwoFactorModal = false;
                            _totpController.clear();
                            _recoveryCodeController.clear();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF475569)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF94A3B8))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isVerifying2FA ? null : _handleVerify2FA,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE85D10),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isVerifying2FA
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                l10n.verifyButton,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
