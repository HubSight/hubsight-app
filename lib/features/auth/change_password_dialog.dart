import 'package:flutter/material.dart';
import 'package:hubsight_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';
import '../../core/localization/error_localizer.dart';
import '../../core/network/sdk_provider.dart';
import '../../core/theme/app_theme.dart';

class ChangePasswordDialog extends ConsumerStatefulWidget {
  final bool isForced;

  const ChangePasswordDialog({
    super.key,
    this.isForced = false,
  });

  @override
  ConsumerState<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(AppLocalizations l10n) async {
    final oldPass = _oldPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    setState(() => _errorMessage = null);

    if (oldPass.isEmpty) {
      setState(() => _errorMessage = l10n.currentPasswordPlaceholder);
      return;
    }

    if (newPass.length < 6) {
      setState(() => _errorMessage = l10n.passwordShort);
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _errorMessage = l10n.passwordMismatch);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final sdk = ref.read(hubsightSdkProvider);
      if (sdk == null) throw const HubSightSessionExpiredException();

      await sdk.auth.changePassword(
        currentPassword: oldPass,
        newPassword: newPass,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(l10n.passwordUpdated),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppErrorLocalizer.localize(e, l10n);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !widget.isForced,
      child: Dialog(
        backgroundColor: HubSightColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: HubSightRadius.roundedCardLg,
          side: const BorderSide(color: HubSightColors.borderDark, width: 1.0),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: HubSightColors.primaryBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.vpn_key_outlined,
                            color: HubSightColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isForced
                                  ? l10n.mustChangePasswordTitle
                                  : l10n.changePasswordTitle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: HubSightColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.isForced
                                  ? l10n.mustChangePasswordDesc
                                  : l10n.changePasswordSubtitle,
                              style: const TextStyle(
                                fontSize: 11,
                                color: HubSightColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (!widget.isForced)
                      IconButton(
                        icon: const Icon(Icons.close, color: HubSightColors.textMuted, size: 18),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: HubSightColors.errorBg,
                      borderRadius: HubSightRadius.roundedCard,
                      border: Border.all(color: HubSightColors.errorBorder, width: 1.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: HubSightColors.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: HubSightColors.errorText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 1. Current Password
                Text(
                  l10n.currentPassword.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: HubSightColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _oldPasswordController,
                  obscureText: _obscureOld,
                  style: const TextStyle(color: HubSightColors.textPrimary, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: l10n.currentPasswordPlaceholder,
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 17),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: HubSightColors.textMuted,
                        size: 17,
                      ),
                      onPressed: () => setState(() => _obscureOld = !_obscureOld),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 2. New Password
                Text(
                  l10n.newPassword.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: HubSightColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  style: const TextStyle(color: HubSightColors.textPrimary, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: l10n.newPasswordPlaceholder,
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 17),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: HubSightColors.textMuted,
                        size: 17,
                      ),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Confirm New Password
                Text(
                  l10n.confirmNewPassword.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: HubSightColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: HubSightColors.textPrimary, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: l10n.confirmNewPasswordPlaceholder,
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 17),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: HubSightColors.textMuted,
                        size: 17,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    if (!widget.isForced) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: HubSightColors.surfaceDark,
                            side: const BorderSide(color: HubSightColors.borderDark),
                            shape: RoundedRectangleBorder(borderRadius: HubSightRadius.roundedXl),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            l10n.cancel,
                            style: const TextStyle(
                              color: HubSightColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: widget.isForced ? 1 : 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _handleSubmit(l10n),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HubSightColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: HubSightRadius.roundedXl),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                l10n.savePassword,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
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
