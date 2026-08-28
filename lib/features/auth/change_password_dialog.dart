import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
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
      final apiClient = ref.read(apiClientProvider);
      final success = await apiClient.changePassword(oldPass, newPass);

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.pop(context);
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          setState(() => _errorMessage = 'Không thể đổi mật khẩu. Vui lòng kiểm tra mật khẩu hiện tại.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể đổi mật khẩu. Vui lòng kiểm tra mật khẩu hiện tại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                children: [
                  // Key icon in light orange container
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: const Icon(
                      Icons.vpn_key_outlined,
                      color: Color(0xFFE85D10),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.changePasswordTitle,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.changePasswordSubtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close Button
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Field 1: Mật khẩu hiện tại
              _buildPasswordField(
                label: l10n.currentPassword,
                hintText: l10n.currentPasswordPlaceholder,
                controller: _oldPasswordController,
                obscureText: _obscureOld,
                onToggleObscure: () => setState(() => _obscureOld = !_obscureOld),
              ),

              const SizedBox(height: 16),

              // Field 2: Mật khẩu mới
              _buildPasswordField(
                label: l10n.newPassword,
                hintText: l10n.newPasswordPlaceholder,
                controller: _newPasswordController,
                obscureText: _obscureNew,
                onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
              ),

              const SizedBox(height: 16),

              // Field 3: Xác nhận mật khẩu mới
              _buildPasswordField(
                label: l10n.confirmNewPassword,
                hintText: l10n.confirmNewPasswordPlaceholder,
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),

              const SizedBox(height: 24),

              // Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n.cancel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleSubmit(l10n),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE85D10),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.savePassword,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE85D10)),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
              onPressed: onToggleObscure,
            ),
          ),
        ),
      ],
    );
  }
}
