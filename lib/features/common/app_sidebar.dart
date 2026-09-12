import 'package:flutter/material.dart';
import 'package:cctv_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/sdk_provider.dart';
import '../../core/services/fcm_service.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../auth/change_password_dialog.dart';
import '../auth/login_screen.dart';
import '../camera/playback_screen.dart';
import '../notifications/notification_screen.dart';
import '../settings/settings_screen.dart';

class AppSidebar extends ConsumerStatefulWidget {
  final String activeRoute;

  const AppSidebar({
    super.key,
    this.activeRoute = 'home',
  });

  @override
  ConsumerState<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  bool _showUserMenu = false;

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
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
    final currentUser = ref.watch(hubsightSdkProvider)?.auth.currentUser;
    final appLocale = ref.watch(appLocaleProvider);

    return Drawer(
      backgroundColor: HubSightColors.cardDark,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: HubSightColors.borderDark, width: 1.0),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Bar: Logo, Title, Subtitle, Close Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              child: Row(
                children: [
                  // Orange Camera Logo Box
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: HubSightColors.primary,
                      borderRadius: HubSightRadius.roundedXl,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HubSight',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: HubSightColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          l10n.sidebarSubtitle,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: HubSightColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close Button
                  IconButton(
                    icon: const Icon(Icons.close, color: HubSightColors.textMuted, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),

            // 2. Top User Workspace & Quick Controls (Linear / Slack pattern)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // User Profile Button
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() => _showUserMenu = !_showUserMenu);
                          },
                          borderRadius: HubSightRadius.roundedXl,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: _showUserMenu
                                  ? HubSightColors.primaryBg
                                  : HubSightColors.surfaceDark,
                              borderRadius: HubSightRadius.roundedXl,
                              border: Border.all(
                                color: _showUserMenu
                                    ? HubSightColors.primaryLight
                                    : HubSightColors.borderDark,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                // User Avatar
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    color: Color(0x33DC2626),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 17,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Name and Tag
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentUser?.fullName.isNotEmpty == true
                                            ? currentUser!.fullName
                                            : 'Administrator',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: HubSightColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0x33DC2626),
                                              borderRadius: BorderRadius.circular(3),
                                              border: Border.all(color: const Color(0x66DC2626)),
                                            ),
                                            child: Text(
                                              currentUser?.role.toUpperCase() ?? l10n.adminRole,
                                              style: const TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFFCA5A5),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '@${currentUser?.username ?? "admin"}',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              color: HubSightColors.textMuted,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.unfold_more_rounded,
                                  size: 15,
                                  color: _showUserMenu
                                      ? HubSightColors.primary
                                      : HubSightColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Notification Bell Button
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationScreen()),
                          );
                        },
                        borderRadius: HubSightRadius.roundedXl,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: HubSightColors.surfaceDark,
                            borderRadius: HubSightRadius.roundedXl,
                            border: Border.all(color: HubSightColors.borderDark, width: 1.0),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: HubSightColors.textSecondary,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Language Switcher Row Under User
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () {
                      ref.read(appLocaleProvider.notifier).toggleLocale();
                    },
                    borderRadius: HubSightRadius.roundedXl,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: HubSightColors.surfaceDark,
                        borderRadius: HubSightRadius.roundedXl,
                        border: Border.all(color: HubSightColors.borderDark, width: 1.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.language_rounded,
                                  size: 14, color: HubSightColors.textMuted),
                              const SizedBox(width: 8),
                              Text(
                                l10n.menuLanguage,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: HubSightColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            appLocale.languageCode == 'vi'
                                ? '🇻🇳 Tiếng Việt'
                                : '🇬🇧 English',
                            style: const TextStyle(
                              fontSize: 11,
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
            ),

            // 3. User Dropdown Popover (when toggled)
            if (_showUserMenu) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: HubSightColors.cardDark,
                    borderRadius: HubSightRadius.roundedCard,
                    border: Border.all(color: HubSightColors.borderDark, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Option 1: Cài đặt thiết bị & Bảo mật
                      ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(
                          Icons.tune_rounded,
                          color: HubSightColors.primary,
                          size: 18,
                        ),
                        title: Text(
                          l10n.settingsTitle,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: HubSightColors.textPrimary,
                          ),
                        ),
                        onTap: () {
                          setState(() => _showUserMenu = false);
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),

                      // Option 2: Đổi mật khẩu
                      ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(
                          Icons.vpn_key_outlined,
                          color: HubSightColors.textSecondary,
                          size: 18,
                        ),
                        title: Text(
                          l10n.changePasswordTitle,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: HubSightColors.textPrimary,
                          ),
                        ),
                        onTap: () {
                          setState(() => _showUserMenu = false);
                          _showChangePasswordDialog();
                        },
                      ),

                      const Divider(height: 1, color: HubSightColors.borderDark),

                      // Option 3: Đăng xuất
                      ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(
                          Icons.logout_rounded,
                          color: HubSightColors.error,
                          size: 18,
                        ),
                        title: Text(
                          l10n.logout,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: HubSightColors.error,
                          ),
                        ),
                        onTap: () {
                          setState(() => _showUserMenu = false);
                          _handleLogout();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 6),
            const Divider(height: 1, color: HubSightColors.borderDark),
            const SizedBox(height: 6),

            // 4. Navigation Menu Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                children: [
                  // Section 1: GIÁM SÁT
                  const Padding(
                    padding: EdgeInsets.only(left: 10, top: 8, bottom: 4),
                    child: Text(
                      'GIÁM SÁT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: HubSightColors.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                  // Xem lại (Playback)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.videocam_outlined,
                    label: l10n.menuPlayback,
                    isSelected: widget.activeRoute == 'home',
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.activeRoute != 'home') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const PlaybackScreen()),
                        );
                      }
                    },
                  ),

                  // Lưới Camera (MultiView / Dashboard)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.grid_view_rounded,
                    label: l10n.dashboardTitle,
                    isSelected: widget.activeRoute == 'dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.activeRoute != 'dashboard') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const DashboardScreen()),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 10),

                  // Section 2: HỆ THỐNG
                  const Padding(
                    padding: EdgeInsets.only(left: 10, top: 8, bottom: 4),
                    child: Text(
                      'HỆ THỐNG',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: HubSightColors.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                  // Notifications / Thông báo
                  _buildMenuItem(
                    context: context,
                    icon: Icons.notifications_none_rounded,
                    label: l10n.notificationTitle,
                    isSelected: widget.activeRoute == 'notifications',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationScreen()),
                      );
                    },
                  ),

                  // Settings / Cài đặt
                  _buildMenuItem(
                    context: context,
                    icon: Icons.tune_rounded,
                    label: l10n.settingsTitle,
                    isSelected: widget.activeRoute == 'settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 5. Version and Copyright Footer
            const Divider(height: 1, color: HubSightColors.borderDark),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: Column(
                children: [
                  Text(
                    l10n.footerVersion,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: HubSightColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.footerCopyright,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: HubSightColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: HubSightRadius.roundedXl,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? HubSightColors.primary : Colors.transparent,
            borderRadius: HubSightRadius.roundedXl,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : HubSightColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : HubSightColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
