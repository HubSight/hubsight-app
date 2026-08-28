import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  void _handleLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      backgroundColor: Colors.white,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(0)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Header Bar: Logo, Title, Subtitle, Close Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                children: [
                  // Orange logo
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE85D10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HubSight',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.sidebarSubtitle,
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
                    icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 2. Navigation Menu Items List (Only 1 item: Home/Trang chủ)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_showUserMenu) {
                    setState(() => _showUserMenu = false);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  children: [
                    // Home / Trang chủ -> Navigate to playback screen
                    _buildMenuItem(
                      context: context,
                      icon: Icons.home_outlined,
                      label: l10n.menuHome,
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
                  ],
                ),
              ),
            ),

            // 3. User Floating Menu Popup (Shown above the user card if active)
            if (_showUserMenu) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header inside popup
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Administrator',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@admin • ${l10n.adminRole}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      // Option 1: Cài đặt thiết bị & Bảo mật
                      ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFFE85D10),
                          size: 20,
                        ),
                        title: Text(
                          l10n.settingsTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0F172A),
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
                          color: Color(0xFF475569),
                          size: 20,
                        ),
                        title: Text(
                          l10n.changePasswordTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        onTap: () {
                          setState(() => _showUserMenu = false);
                          _showChangePasswordDialog();
                        },
                      ),

                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      // Option 3: Đăng xuất
                      ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                        title: Text(
                          l10n.logout,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFDC2626),
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
              const SizedBox(height: 10),
            ],

            // 4. Language Selector Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language, size: 20, color: Color(0xFF64748B)),
                      const SizedBox(width: 10),
                      Text(
                        l10n.menuLanguage,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  // Language badge pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: Text(
                      l10n.languageBadge,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE85D10),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 16, color: Color(0xFFE2E8F0)),

            // 5. User Profile Card & Notification Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // User Profile (Clickable -> Opens Popup Menu)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showUserMenu = !_showUserMenu;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: _showUserMenu ? const Color(0xFFFFFBF7) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: _showUserMenu
                              ? Border.all(color: const Color(0xFFFED7AA), width: 1.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                            // User Avatar
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                color: Color(0xFFEF4444),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Name and Tag
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Administrator',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFFFECACA)),
                                        ),
                                        child: Text(
                                          l10n.adminRole,
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFDC2626),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        '@admin',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF64748B),
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
                              size: 18,
                              color: _showUserMenu ? const Color(0xFFE85D10) : const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Notification Bell Button
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF334155),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // 6. Version and Copyright Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                children: [
                  Text(
                    l10n.footerVersion,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.footerCopyright,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE85D10) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
