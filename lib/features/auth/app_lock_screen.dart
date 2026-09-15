import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/biometric_service.dart';
import '../../core/network/sdk_provider.dart';
import '../../core/services/fcm_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'login_screen.dart';
import '../common/main_tab_screen.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;
  final bool isCreatingPin;
  final ValueChanged<String>? onPinCreated;

  const AppLockScreen({
    super.key,
    required this.onUnlocked,
    this.isCreatingPin = false,
    this.onPinCreated,
  });

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String _confirmedPin = '';
  bool _isConfirming = false;
  String _errorMessage = '';
  late AnimationController _shakeController;
  String _biometricLabel = 'Face ID';
  bool _canUseBiometric = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _initBiometrics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    if (l10n != null) {
      _updateBiometricLabel(l10n);
    }
  }

  Future<void> _updateBiometricLabel(AppLocalizations l10n) async {
    final bioService = ref.read(biometricServiceProvider);
    final label = await bioService.getLocalizedBiometricTypeLabel(l10n);
    if (mounted) {
      setState(() {
        _biometricLabel = label;
      });
    }
  }

  Future<void> _initBiometrics() async {
    final bioService = ref.read(biometricServiceProvider);
    final label = await bioService.getBiometricTypeLabel();
    final canAuth = await bioService.canAuthenticateWithBiometrics();

    if (mounted) {
      setState(() {
        _biometricLabel = label;
        _canUseBiometric = canAuth;
      });
    }

    // Auto-prompt biometric only if device actually has enrolled biometrics and biometric is enabled
    if (!widget.isCreatingPin && canAuth && bioService.isBiometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryBiometricUnlock();
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onUnlockSuccess() {
    HapticFeedback.mediumImpact();
    widget.onUnlocked();
    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainTabScreen(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    }
  }

  Future<void> _tryBiometricUnlock() async {
    final bioService = ref.read(biometricServiceProvider);
    final canAuth = await bioService.canAuthenticateWithBiometrics();
    final l10n = mounted ? AppLocalizations.of(context) : null;

    if (!canAuth) {
      _showError(l10n?.loginBiometricNotEnrolled ??
          'Thiết bị chưa cài đặt vân tay hoặc Face ID trong Cài đặt máy.');
      return;
    }

    final reason = l10n?.lockBiometricReason(_biometricLabel) ??
        'Xác thực $_biometricLabel để mở khóa HubSight';

    final success = await bioService.authenticate(
      localizedReason: reason,
    );
    if (success && mounted) {
      if (!bioService.isBiometricEnabled) {
        await bioService.setBiometricEnabled(true);
      }
      _onUnlockSuccess();
    } else if (mounted) {
      _showError(l10n?.loginBiometricFailed ?? 'Xác thực sinh trắc học thất bại hoặc đã bị huỷ.');
    }
  }

  void _onKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin += digit;
        _errorMessage = '';
      });

      if (_enteredPin.length == 4) {
        _handlePinComplete();
      }
    }
  }

  void _onDeletePress() {
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      });
    }
  }

  void _handlePinComplete() async {
    final bioService = ref.read(biometricServiceProvider);
    final l10n = mounted ? AppLocalizations.of(context) : null;

    if (widget.isCreatingPin) {
      if (!_isConfirming) {
        setState(() {
          _confirmedPin = _enteredPin;
          _enteredPin = '';
          _isConfirming = true;
        });
      } else {
        if (_enteredPin == _confirmedPin) {
          await bioService.savePin(_enteredPin);
          widget.onPinCreated?.call(_enteredPin);
          _onUnlockSuccess();
        } else {
          _showError(l10n?.lockPinMismatch ?? 'Mã PIN xác nhận không khớp');
          setState(() {
            _enteredPin = '';
            _confirmedPin = '';
            _isConfirming = false;
          });
        }
      }
    } else {
      if (!bioService.hasPin) {
        _showError(l10n?.lockNoPinPrompt(_biometricLabel) ?? 'Chưa thiết lập mã PIN');
        _tryBiometricUnlock();
        return;
      }
      final isValid = bioService.verifyPin(_enteredPin);
      if (isValid) {
        _onUnlockSuccess();
      } else {
        _showError(l10n?.lockPinIncorrect ?? 'Mã PIN không đúng');
        setState(() {
          _enteredPin = '';
        });
      }
    }
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    setState(() {
      _errorMessage = message;
    });
    _shakeController.forward(from: 0.0);
  }

  void _handleLogout() async {
    final sdk = ref.read(hubsightSdkProvider);
    await ref.read(fcmServiceProvider).unregisterTokenForLogout();
    if (sdk != null) {
      await sdk.auth.logout();
    }
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bioService = ref.watch(biometricServiceProvider);
    final l10n = AppLocalizations.of(context);

    String titleText = l10n?.lockEnterPin ?? 'Nhập mã PIN bảo mật';
    if (widget.isCreatingPin) {
      titleText = _isConfirming
          ? (l10n?.lockConfirmPin ?? 'Xác nhận lại mã PIN mới')
          : (l10n?.lockSetNewPin ?? 'Thiết lập mã PIN 4 chữ số');
    } else if (_canUseBiometric || bioService.isBiometricEnabled) {
      titleText = l10n?.lockEnterPinOrBiometric(_biometricLabel) ??
          'Nhập mã PIN hoặc sử dụng $_biometricLabel';
    }

    return Scaffold(
      backgroundColor: HubSightColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),

            // Logo & Title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HubSightColors.cardDark,
                shape: BoxShape.circle,
                border: Border.all(color: HubSightColors.borderDark, width: 1.0),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: HubSightColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              titleText,
              style: const TextStyle(
                color: HubSightColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'HubSight Surveillance Security',
              style: TextStyle(
                color: HubSightColors.textMuted,
                fontSize: 12.5,
              ),
            ),

            const SizedBox(height: 32),

            // PIN Indicator Dots with Shake Animation
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final offset = _shakeController.value * 12 * (1 - _shakeController.value) * 4;
                return Transform.translate(
                  offset: Offset(offset * (offset.toInt().isEven ? 1 : -1), 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _enteredPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? const Color(0xFFE85D10) : Colors.transparent,
                          border: Border.all(
                            color: isFilled ? const Color(0xFFE85D10) : const Color(0xFF475569),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),

            // Error message
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                _errorMessage,
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const Spacer(flex: 2),

            // Keypad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  const SizedBox(height: 18),
                  _buildKeypadRow(['4', '5', '6']),
                  const SizedBox(height: 18),
                  _buildKeypadRow(['7', '8', '9']),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Biometric Icon Button
                      if (!widget.isCreatingPin && (_canUseBiometric || bioService.isBiometricEnabled))
                        _buildActionButton(
                          icon: _biometricLabel == 'Face ID'
                              ? Icons.face_rounded
                              : Icons.fingerprint_rounded,
                          onTap: _tryBiometricUnlock,
                        )
                      else
                        const SizedBox(width: 72, height: 72),

                      // Digit 0
                      _buildDigitButton('0'),

                      // Backspace Button
                      _buildActionButton(
                        icon: Icons.backspace_outlined,
                        onTap: _onDeletePress,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // Bottom Actions (Logout or Cancel)
            if (!widget.isCreatingPin)
              TextButton(
                onPressed: _handleLogout,
                child: Text(
                  l10n?.lockLogoutAccount ?? 'Đăng xuất khỏi tài khoản',
                  style: const TextStyle(
                    color: HubSightColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n?.cancel ?? 'Huỷ',
                  style: const TextStyle(color: HubSightColors.textMuted, fontSize: 13),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: digits.map((d) => _buildDigitButton(d)).toList(),
    );
  }

  Widget _buildDigitButton(String digit) {
    return InkWell(
      onTap: () => _onKeyPress(digit),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: HubSightColors.surfaceDark,
          shape: BoxShape.circle,
          border: Border.all(color: HubSightColors.borderDark, width: 1.0),
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              color: HubSightColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            color: HubSightColors.primary,
            size: 30,
          ),
        ),
      ),
    );
  }
}

