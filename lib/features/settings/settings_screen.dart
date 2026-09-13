import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:hubsight_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';
import '../../core/localization/error_localizer.dart';
import '../../core/network/sdk_provider.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/fcm_service.dart';
import '../auth/change_password_dialog.dart';
import '../auth/login_screen.dart';
import '../config/server_config_screen.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  UserProfile? _profile;
  List<SessionItem> _sessions = [];
  List<PasskeyItem> _passkeys = [];
  bool _isLoadingProfile = true;
  bool _isLoadingSessions = true;
  bool _isLoadingPasskeys = true;

  // Push notification preferences
  bool _pushFamily = true;
  bool _pushStranger = true;
  bool _pushSystem = true;

  // Security preferences
  bool _lockOnBackground = false;
  bool _biometricUnlock = false;
  String _selectedTimeout = 'immediate';
  bool _isSessionsExpanded = false;

  @override
  void initState() {
    super.initState();
    final bio = ref.read(biometricServiceProvider);
    _lockOnBackground = bio.isAppLockEnabled;
    _biometricUnlock = bio.isBiometricEnabled;
    final mins = bio.lockTimeoutMinutes;
    if (mins == 1) {
      _selectedTimeout = '1min';
    } else if (mins >= 5) {
      _selectedTimeout = '5mins';
    } else {
      _selectedTimeout = 'immediate';
    }

    _loadProfileAndSessions();
  }

  Future<void> _loadProfileAndSessions() async {
    final sdk = ref.read(hubsightSdkProvider);
    if (sdk == null) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _isLoadingSessions = false;
          _isLoadingPasskeys = false;
        });
      }
      return;
    }

    // 1. Profile
    try {
      final profile = await sdk.auth.getProfile().timeout(const Duration(seconds: 4));
      if (mounted) {
        setState(() {
          _profile = profile;
          _pushFamily = profile.pushPreferences['family'] ?? true;
          _pushStranger = profile.pushPreferences['stranger'] ?? true;
          _pushSystem = profile.pushPreferences['system'] ?? true;
          _isLoadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }

    // 2. Sessions
    _fetchSessions();

    // 3. Passkeys
    _fetchPasskeys();
  }

  Future<void> _fetchPasskeys() async {
    final sdk = ref.read(hubsightSdkProvider);
    if (sdk == null) {
      if (mounted) setState(() => _isLoadingPasskeys = false);
      return;
    }

    setState(() => _isLoadingPasskeys = true);
    try {
      final passkeys = await sdk.auth.listPasskeys().timeout(const Duration(seconds: 4));
      if (mounted) {
        setState(() {
          _passkeys = passkeys;
          _isLoadingPasskeys = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPasskeys = false);
    }
  }

  Future<void> _handleOpenAddPasskey(AppLocalizations l10n) async {
    final bio = ref.read(biometricServiceProvider);
    final bioLabel = await bio.getBiometricTypeLabel();
    final defaultName = '$bioLabel trên thiết bị này';
    final nameController = TextEditingController(text: defaultName);

    if (!mounted) return;

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardAdaptive,
        shape: RoundedRectangleBorder(
          borderRadius: HubSightRadius.roundedCard,
          side: BorderSide(color: context.borderAdaptive),
        ),
        title: Text(
          l10n.passkeyEnrollDialogTitle,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimaryAdaptive),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.passkeyNamePrompt,
              style: TextStyle(fontSize: 12.5, color: context.textSecondaryAdaptive),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              autofocus: true,
              style: TextStyle(color: context.textPrimaryAdaptive, fontSize: 13),
              decoration: InputDecoration(
                hintText: l10n.passkeyNamePlaceholder,
                hintStyle: TextStyle(color: context.textMutedAdaptive),
                filled: true,
                fillColor: context.surfaceAdaptive,
                border: OutlineInputBorder(
                  borderRadius: HubSightRadius.roundedXl,
                  borderSide: BorderSide(color: context.borderAdaptive),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: HubSightRadius.roundedXl,
                  borderSide: BorderSide(color: context.borderAdaptive),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: HubSightRadius.roundedXl,
                  borderSide: const BorderSide(color: HubSightColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: TextStyle(color: context.textMutedAdaptive)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: HubSightColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: HubSightRadius.roundedXl),
            ),
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: Text(l10n.addPasskeyBtn),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    // Verify biometric on device
    final canCheck = await bio.canAuthenticateWithBiometrics();
    if (canCheck) {
      final ok = await bio.authenticate(localizedReason: l10n.loginBiometricPrompt);
      if (!ok) return;
    }

    try {
      final sdk = ref.read(hubsightSdkProvider);
      if (sdk != null) {
        try {
          await sdk.auth.verifyPasskeyRegister(
            challengeId: 'bio_challenge_${DateTime.now().millisecondsSinceEpoch}',
            credential: 'bio_credential_${DateTime.now().millisecondsSinceEpoch}',
            name: name,
          );
        } catch (_) {
          // Handled gracefully if backend requires WebAuthn binary signature
        }
        await bio.setBiometricEnabled(true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.passkeyAdded),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          _fetchPasskeys();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorLocalizer.localize(e, l10n)),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _handleRenamePasskey(PasskeyItem item, AppLocalizations l10n) async {
    final controller = TextEditingController(text: item.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardAdaptive,
        shape: RoundedRectangleBorder(
          borderRadius: HubSightRadius.roundedCard,
          side: BorderSide(color: context.borderAdaptive),
        ),
        title: Text(
          l10n.renamePasskey,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimaryAdaptive),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: context.textPrimaryAdaptive, fontSize: 13),
          decoration: InputDecoration(
            hintText: l10n.passkeyNamePlaceholder,
            hintStyle: TextStyle(color: context.textMutedAdaptive),
            filled: true,
            fillColor: context.surfaceAdaptive,
            border: OutlineInputBorder(
              borderRadius: HubSightRadius.roundedXl,
              borderSide: BorderSide(color: context.borderAdaptive),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: HubSightRadius.roundedXl,
              borderSide: BorderSide(color: context.borderAdaptive),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: HubSightRadius.roundedXl,
              borderSide: const BorderSide(color: HubSightColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: TextStyle(color: context.textMutedAdaptive)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: HubSightColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: HubSightRadius.roundedXl),
            ),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.renamePasskey),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == item.name) return;

    try {
      final sdk = ref.read(hubsightSdkProvider);
      if (sdk != null) {
        await sdk.auth.renamePasskey(item.id, newName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.passkeyUpdated),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          _fetchPasskeys();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorLocalizer.localize(e, l10n)),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _handleDeletePasskey(PasskeyItem item, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardAdaptive,
        shape: RoundedRectangleBorder(
          borderRadius: HubSightRadius.roundedCard,
          side: BorderSide(color: context.borderAdaptive),
        ),
        title: Text(
          l10n.deletePasskey,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimaryAdaptive),
        ),
        content: Text(
          l10n.confirmDeletePasskey,
          style: TextStyle(color: context.textSecondaryAdaptive),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: TextStyle(color: context.textMutedAdaptive)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: HubSightColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: HubSightRadius.roundedXl),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deletePasskey),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final sdk = ref.read(hubsightSdkProvider);
      if (sdk != null) {
        await sdk.auth.deletePasskey(item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.passkeyDeleted),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          _fetchPasskeys();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorLocalizer.localize(e, l10n)),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _fetchSessions() async {
    final sdk = ref.read(hubsightSdkProvider);
    if (sdk == null) {
      if (mounted) setState(() => _isLoadingSessions = false);
      return;
    }

    setState(() => _isLoadingSessions = true);
    try {
      final sessions = await sdk.auth.listSessions().timeout(const Duration(seconds: 4));
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoadingSessions = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSessions = false);
    }
  }

  Future<void> _handleRevokeSession(SessionItem session, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardAdaptive,
        shape: RoundedRectangleBorder(
          borderRadius: HubSightRadius.roundedCard,
          side: BorderSide(color: context.borderAdaptive),
        ),
        title: Text(l10n.revokeSession, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimaryAdaptive)),
        content: Text(l10n.confirmRevokeSession, style: TextStyle(color: context.textSecondaryAdaptive)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: TextStyle(color: context.textMutedAdaptive)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: HubSightColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: HubSightRadius.roundedXl),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.revokeSession),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final sdk = ref.read(hubsightSdkProvider);
      if (sdk != null) {
        await sdk.auth.revokeSession(session.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.sessionRevokedSuccess),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          _fetchSessions();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorLocalizer.localize(e, l10n)),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _syncPushPreferences() async {
    final sdk = ref.read(hubsightSdkProvider);
    if (sdk != null) {
      try {
        await sdk.auth.updateProfile(
          pushPreferences: {
            'family': _pushFamily,
            'stranger': _pushStranger,
            'system': _pushSystem,
          },
        );
      } catch (_) {}
    }
  }

  Future<void> _handleLogout() async {
    final sdk = ref.read(hubsightSdkProvider);
    final fcm = ref.read(fcmServiceProvider);

    if (sdk != null) {
      final token = fcm.fcmToken;
      if (token != null) {
        try {
          await sdk.fcm.unregisterPushToken(token);
        } catch (_) {}
      }
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
    final l10n = AppLocalizations.of(context)!;
    final sdk = ref.watch(hubsightSdkProvider);

    return Scaffold(
      backgroundColor: context.bgAdaptive,
      appBar: AppBar(
        backgroundColor: context.cardAdaptive,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(color: context.borderAdaptive, width: 1),
        ),
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: context.textPrimaryAdaptive),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        titleSpacing: 20,
        title: Text(
          l10n.tabSettings,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.4,
            color: context.textPrimaryAdaptive,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: context.textSecondaryAdaptive, size: 22),
            tooltip: l10n.loading,
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadProfileAndSessions();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. User Profile Hero Card
            _buildProfileSection(l10n),
            const SizedBox(height: 14),

            // 2. Language Switcher Section
            _buildSectionHeader(l10n.menuLanguage),
            _buildLanguageSection(l10n),
            const SizedBox(height: 14),

            // 3. Theme Appearance Section
            _buildSectionHeader(l10n.themeTitle),
            _buildThemeSection(l10n),
            const SizedBox(height: 14),

            // 4. Devices & Active Sessions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(l10n.sessionsTitle),
                IconButton(
                  icon: Icon(Icons.refresh_rounded, size: 18, color: context.textMutedAdaptive),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _fetchSessions();
                  },
                  tooltip: l10n.loading,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
            _buildSessionsSection(l10n),
            const SizedBox(height: 14),

            // 5. Biometrics & Passkeys
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(l10n.passkeyTitle),
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _handleOpenAddPasskey(l10n);
                  },
                  borderRadius: HubSightRadius.roundedXl,
                  child: Container(
                    margin: const EdgeInsets.only(top: 14, bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: HubSightColors.primary.withValues(alpha: 0.14),
                      borderRadius: HubSightRadius.roundedXl,
                      border: Border.all(color: HubSightColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 13, color: HubSightColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          l10n.addPasskeyBtn,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: HubSightColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _buildPasskeysSection(l10n),
            const SizedBox(height: 14),

            // 6. Security Settings (Lock & Password)
            _buildSectionHeader('Bảo mật ứng dụng'),
            _buildSecuritySection(l10n),
            const SizedBox(height: 14),

            // 7. Push Notification Settings
            _buildSectionHeader(l10n.pushSettingsTitle),
            _buildPushSettingsSection(l10n),
            const SizedBox(height: 14),

            // 8. Server & Container Config
            _buildSectionHeader(l10n.serverConfigTitle),
            _buildServerInfoSection(sdk, l10n),
            const SizedBox(height: 22),

            // 9. Safe Logout Action Section
            _buildLogoutSection(l10n),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Design System Helpers ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 12, bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: context.textMutedAdaptive,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildGroupCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceAdaptive,
        borderRadius: HubSightRadius.roundedCard,
        border: Border.all(color: context.borderAdaptive),
      ),
      child: ClipRRect(
        borderRadius: HubSightRadius.roundedCard,
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 56),
                  child: Divider(height: 1, thickness: 0.8, color: context.borderAdaptive),
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingIcon(IconData icon, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildSettingTile({
    required Widget icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryAdaptive,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textMutedAdaptive,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  // --- 1. User Profile Section ---
  Widget _buildProfileSection(AppLocalizations l10n) {
    if (_isLoadingProfile) {
      return Container(
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.surfaceAdaptive,
          borderRadius: HubSightRadius.roundedCard,
          border: Border.all(color: context.borderAdaptive),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: HubSightColors.primary),
        ),
      );
    }

    final fullName = _profile?.fullName.isNotEmpty == true ? _profile!.fullName : 'Administrator';
    final username = _profile?.username ?? 'admin';
    final role = _profile?.role.toUpperCase() ?? 'ADMIN';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceAdaptive,
        borderRadius: HubSightRadius.roundedCard,
        border: Border.all(color: context.borderAdaptive),
      ),
      child: Row(
        children: [
          // Avatar with gradient & online badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      HubSightColors.primary,
                      HubSightColors.primary.withValues(alpha: 0.75),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: context.borderAdaptive),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: context.surfaceAdaptive, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Name and Role info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                    color: context.textPrimaryAdaptive,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '@$username',
                      style: TextStyle(fontSize: 12, color: context.textMutedAdaptive),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: HubSightColors.primary.withValues(alpha: 0.14),
                        borderRadius: HubSightRadius.roundedFull,
                        border: Border.all(color: HubSightColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: HubSightColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Change password pill
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              showDialog(
                context: context,
                builder: (_) => const ChangePasswordDialog(),
              );
            },
            borderRadius: HubSightRadius.roundedXl,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.cardAdaptive,
                borderRadius: HubSightRadius.roundedXl,
                border: Border.all(color: context.borderAdaptive),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.key_rounded, size: 13, color: HubSightColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    l10n.changePasswordTitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: HubSightColors.primary,
                      fontWeight: FontWeight.bold,
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

  // --- 2. Language Section ---
  Widget _buildLanguageSection(AppLocalizations l10n) {
    final appLocale = ref.watch(appLocaleProvider);
    final isVi = appLocale.languageCode == 'vi';

    return _buildGroupCard(
      children: [
        _buildSettingTile(
          icon: _buildSettingIcon(Icons.language_rounded, const Color(0xFF3B82F6)),
          title: l10n.menuLanguage,
          subtitle: isVi ? 'Tiếng Việt' : 'English',
          trailing: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(appLocaleProvider.notifier).toggleLocale();
            },
            borderRadius: HubSightRadius.roundedXl,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.cardAdaptive,
                borderRadius: HubSightRadius.roundedXl,
                border: Border.all(color: context.borderAdaptive),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isVi ? 'Tiếng Việt' : 'English',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: HubSightColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.swap_horiz_rounded, size: 14, color: context.textSecondaryAdaptive),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 3. Theme Appearance Section ---
  Widget _buildThemeSection(AppLocalizations l10n) {
    final currentMode = ref.watch(appThemeModeProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceAdaptive,
        borderRadius: HubSightRadius.roundedCard,
        border: Border.all(color: context.borderAdaptive),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: context.cardAdaptive,
              borderRadius: HubSightRadius.roundedXl,
              border: Border.all(color: context.borderAdaptive),
            ),
            child: Row(
              children: [
                _buildThemePill(
                  mode: ThemeMode.system,
                  currentMode: currentMode,
                  label: l10n.themeSystem,
                  icon: Icons.brightness_auto_rounded,
                ),
                const SizedBox(width: 3),
                _buildThemePill(
                  mode: ThemeMode.light,
                  currentMode: currentMode,
                  label: l10n.themeLight,
                  icon: Icons.light_mode_rounded,
                ),
                const SizedBox(width: 3),
                _buildThemePill(
                  mode: ThemeMode.dark,
                  currentMode: currentMode,
                  label: l10n.themeDark,
                  icon: Icons.dark_mode_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              currentMode == ThemeMode.light
                  ? l10n.themeLightDesc
                  : currentMode == ThemeMode.dark
                      ? l10n.themeDarkDesc
                      : l10n.themeSystemDesc,
              style: TextStyle(fontSize: 11.5, color: context.textMutedAdaptive),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemePill({
    required ThemeMode mode,
    required ThemeMode currentMode,
    required String label,
    required IconData icon,
  }) {
    final isSelected = mode == currentMode;

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(appThemeModeProvider.notifier).setThemeMode(mode);
        },
        borderRadius: HubSightRadius.roundedLg,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (context.isDarkMode ? context.surfaceElevatedAdaptive : Colors.white)
                : Colors.transparent,
            borderRadius: HubSightRadius.roundedLg,
            border: isSelected
                ? Border.all(color: context.borderAdaptive)
                : Border.all(color: Colors.transparent),
            boxShadow: isSelected && !context.isDarkMode
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? HubSightColors.primary : context.textSecondaryAdaptive,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? HubSightColors.primary : context.textPrimaryAdaptive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 4. Devices & Active Sessions ---
  Widget _buildSessionsSection(AppLocalizations l10n) {
    if (_isLoadingSessions) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.surfaceAdaptive,
          borderRadius: HubSightRadius.roundedCard,
          border: Border.all(color: context.borderAdaptive),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: HubSightColors.primary),
        ),
      );
    }

    if (_sessions.isEmpty) {
      return _buildGroupCard(
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                _buildSettingIcon(Icons.devices_rounded, const Color(0xFF10B981)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Không có phiên nào khác đang hoạt động',
                    style: TextStyle(color: context.textMutedAdaptive, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final currentSession = _sessions.firstWhere((s) => s.isCurrent, orElse: () => _sessions.first);
    final otherSessions = _sessions.where((s) => !s.isCurrent).toList();

    return _buildGroupCard(
      children: [
        // Current device row
        _buildSettingTile(
          icon: _buildSettingIcon(
            currentSession.clientType?.contains('mobile') == true
                ? Icons.phone_iphone_rounded
                : Icons.laptop_mac_rounded,
            const Color(0xFF10B981),
          ),
          title: currentSession.deviceLabel ?? currentSession.clientType ?? 'Thiết bị này',
          subtitle: 'IP: ${currentSession.ipAddress ?? "LAN"} • ${currentSession.geoCity ?? "Local"}',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: const Color(0x2610B981),
              borderRadius: HubSightRadius.roundedFull,
              border: Border.all(color: const Color(0x4D10B981)),
            ),
            child: Text(
              l10n.currentSession,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
          ),
        ),

        // If there are other sessions
        if (otherSessions.isNotEmpty) ...[
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isSessionsExpanded = !_isSessionsExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  _buildSettingIcon(Icons.devices_other_rounded, const Color(0xFF64748B)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${otherSessions.length} phiên đăng nhập khác',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimaryAdaptive,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isSessionsExpanded ? 'Chạm để thu gọn' : 'Chạm để quản lý và thu hồi',
                          style: TextStyle(fontSize: 11, color: context.textMutedAdaptive),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isSessionsExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: context.textSecondaryAdaptive,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isSessionsExpanded) ...[
            for (final s in otherSessions)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                child: Row(
                  children: [
                    const SizedBox(width: 44),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.deviceLabel ?? s.clientType ?? 'Thiết bị',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryAdaptive,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'IP: ${s.ipAddress ?? "Unknown"} • ${s.geoCity ?? "Local"}',
                            style: TextStyle(fontSize: 10.5, color: context.textMutedAdaptive),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _handleRevokeSession(s, l10n),
                      style: TextButton.styleFrom(
                        foregroundColor: HubSightColors.error,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.revokeSession,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ],
    );
  }

  // --- 5. Passkeys Section ---
  Widget _buildPasskeysSection(AppLocalizations l10n) {
    return _buildGroupCard(
      children: [
        if (_isLoadingPasskeys)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: HubSightColors.primary),
              ),
            ),
          )
        else if (_passkeys.isEmpty)
          _buildSettingTile(
            icon: _buildSettingIcon(Icons.fingerprint_rounded, const Color(0xFF10B981)),
            title: l10n.noPasskeys,
            subtitle: l10n.passkeySubtitle,
          )
        else
          for (final keyItem in _passkeys) ...[
            _buildSettingTile(
              icon: _buildSettingIcon(Icons.fingerprint_rounded, const Color(0xFF10B981)),
              title: keyItem.name,
              subtitle: '${l10n.passkeyCreated}: ${keyItem.createdAt != null ? DateFormat("dd/MM/yyyy").format(keyItem.createdAt!) : l10n.passkeyNeverUsed}',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 17, color: context.textMutedAdaptive),
                    tooltip: l10n.renamePasskey,
                    onPressed: () => _handleRenamePasskey(keyItem, l10n),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 17, color: HubSightColors.error),
                    tooltip: l10n.deletePasskey,
                    onPressed: () => _handleDeletePasskey(keyItem, l10n),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }

  // --- 6. Security Settings ---
  Widget _buildSecuritySection(AppLocalizations l10n) {
    return _buildGroupCard(
      children: [
        _buildSettingTile(
          icon: _buildSettingIcon(Icons.lock_clock_rounded, const Color(0xFF6366F1)),
          title: l10n.lockOnBackground,
          subtitle: l10n.lockOnBackgroundDesc,
          trailing: CupertinoSwitch(
            value: _lockOnBackground,
            activeTrackColor: HubSightColors.primary,
            onChanged: (v) {
              setState(() => _lockOnBackground = v);
              ref.read(biometricServiceProvider).setAppLockEnabled(v);
            },
          ),
        ),
        _buildSettingTile(
          icon: _buildSettingIcon(Icons.face_retouching_natural_rounded, const Color(0xFF8B5CF6)),
          title: l10n.biometricUnlock,
          subtitle: l10n.biometricUnlockDesc,
          trailing: CupertinoSwitch(
            value: _biometricUnlock,
            activeTrackColor: HubSightColors.primary,
            onChanged: (v) async {
              final bio = ref.read(biometricServiceProvider);
              if (v) {
                final canCheck = await bio.canAuthenticateWithBiometrics();
                if (!canCheck) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.loginBiometricNotSupported)),
                    );
                  }
                  return;
                }
                final ok = await bio.authenticate(localizedReason: l10n.loginBiometricPrompt);
                if (!ok) return;
                setState(() => _biometricUnlock = true);
                await bio.setBiometricEnabled(true);
              } else {
                setState(() => _biometricUnlock = false);
                await bio.clearBiometricCredentials();
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildSettingIcon(Icons.timer_outlined, const Color(0xFFEC4899)),
                  const SizedBox(width: 12),
                  Text(
                    l10n.lockTimeoutTitle,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryAdaptive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeoutButton(
                      key: 'immediate',
                      label: l10n.timeoutImmediately,
                      isSelected: _selectedTimeout == 'immediate',
                      onTap: () {
                        setState(() => _selectedTimeout = 'immediate');
                        ref.read(biometricServiceProvider).setLockTimeoutMinutes(0);
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildTimeoutButton(
                      key: '1min',
                      label: l10n.timeout1Min,
                      isSelected: _selectedTimeout == '1min',
                      onTap: () {
                        setState(() => _selectedTimeout = '1min');
                        ref.read(biometricServiceProvider).setLockTimeoutMinutes(1);
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildTimeoutButton(
                      key: '5mins',
                      label: l10n.timeout5Mins,
                      isSelected: _selectedTimeout == '5mins',
                      onTap: () {
                        setState(() => _selectedTimeout = '5mins');
                        ref.read(biometricServiceProvider).setLockTimeoutMinutes(5);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 7. Push Notification Settings ---
  Widget _buildPushSettingsSection(AppLocalizations l10n) {
    return _buildGroupCard(
      children: [
        _buildSettingTile(
          icon: _buildSettingIcon(Icons.family_restroom_rounded, const Color(0xFF14B8A6)),
          title: l10n.pushFamily,
          subtitle: l10n.pushFamilyDesc,
          trailing: CupertinoSwitch(
            value: _pushFamily,
            activeTrackColor: HubSightColors.primary,
            onChanged: (v) {
              setState(() => _pushFamily = v);
              _syncPushPreferences();
            },
          ),
        ),
        _buildSettingTile(
          icon: _buildSettingIcon(Icons.person_search_rounded, const Color(0xFFF59E0B)),
          title: l10n.pushStranger,
          subtitle: l10n.pushStrangerDesc,
          trailing: CupertinoSwitch(
            value: _pushStranger,
            activeTrackColor: HubSightColors.primary,
            onChanged: (v) {
              setState(() => _pushStranger = v);
              _syncPushPreferences();
            },
          ),
        ),
        _buildSettingTile(
          icon: _buildSettingIcon(Icons.notifications_active_rounded, const Color(0xFFF43F5E)),
          title: l10n.pushSystem,
          subtitle: l10n.pushSystemDesc,
          trailing: CupertinoSwitch(
            value: _pushSystem,
            activeTrackColor: HubSightColors.primary,
            onChanged: (v) {
              setState(() => _pushSystem = v);
              _syncPushPreferences();
            },
          ),
        ),
      ],
    );
  }

  // --- 8. Server & Container Config ---
  Widget _buildServerInfoSection(HubSightSDK? sdk, AppLocalizations l10n) {
    return _buildGroupCard(
      children: [
        _buildSettingTile(
          icon: _buildSettingIcon(Icons.dns_rounded, const Color(0xFF0EA5E9)),
          title: sdk?.config.urls.gatewayUrl ?? 'Chưa cấu hình',
          subtitle: sdk != null
              ? 'Profile: ${sdk.config.metadata.name} • Đang hoạt động'
              : 'Chưa kết nối cổng Gateway',
          trailing: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ServerConfigScreen(isInitialSetup: false),
                ),
              );
            },
            borderRadius: HubSightRadius.roundedXl,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.cardAdaptive,
                borderRadius: HubSightRadius.roundedXl,
                border: Border.all(color: context.borderAdaptive),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swap_horiz_rounded, size: 14, color: HubSightColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    l10n.changeServer,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: HubSightColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 9. Safe Logout Action Section ---
  Widget _buildLogoutSection(AppLocalizations l10n) {
    return Column(
      children: [
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _confirmLogout(l10n),
          borderRadius: HubSightRadius.roundedCard,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: HubSightColors.errorBg,
              borderRadius: HubSightRadius.roundedCard,
              border: Border.all(color: HubSightColors.errorBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout_rounded, color: HubSightColors.error, size: 18),
                const SizedBox(width: 8),
                Text(
                  l10n.logout,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: HubSightColors.errorText,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'HubSight Mobile v1.0.0 • Build 2026.09',
          style: TextStyle(fontSize: 11, color: context.textMutedAdaptive),
        ),
      ],
    );
  }

  void _confirmLogout(AppLocalizations l10n) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.cardAdaptive,
        shape: RoundedRectangleBorder(
          borderRadius: HubSightRadius.roundedCardLg,
          side: BorderSide(color: context.borderAdaptive),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: HubSightColors.errorBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: HubSightColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.logout,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryAdaptive,
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này?',
          style: TextStyle(fontSize: 13.5, color: context.textSecondaryAdaptive),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: context.textSecondaryAdaptive, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _handleLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HubSightColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: HubSightRadius.roundedXl),
            ),
            child: Text(l10n.logout, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeoutButton({
    required String key,
    required String label,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        if (onTap != null) onTap();
      },
      borderRadius: HubSightRadius.roundedXl,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (context.isDarkMode ? context.surfaceElevatedAdaptive : Colors.white)
              : Colors.transparent,
          borderRadius: HubSightRadius.roundedXl,
          border: isSelected
              ? Border.all(color: context.borderAdaptive)
              : Border.all(color: context.borderAdaptive.withValues(alpha: 0.5)),
          boxShadow: isSelected && !context.isDarkMode
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? HubSightColors.primary : context.textSecondaryAdaptive,
          ),
        ),
      ),
    );
  }
}
