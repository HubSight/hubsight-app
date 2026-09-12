import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cctv_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';
import '../../core/localization/error_localizer.dart';
import '../../core/network/sdk_provider.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/fcm_service.dart';
import '../auth/change_password_dialog.dart';
import '../auth/login_screen.dart';
import '../config/server_config_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  UserProfile? _profile;
  List<SessionItem> _sessions = [];
  bool _isLoadingProfile = true;
  bool _isLoadingSessions = true;

  // Push notification preferences
  bool _pushFamily = true;
  bool _pushStranger = true;
  bool _pushSystem = true;

  // Security preferences
  bool _lockOnBackground = false;
  bool _biometricUnlock = false;
  String _selectedTimeout = 'immediate';

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
    if (sdk == null) return;

    // 1. Profile
    try {
      final profile = await sdk.auth.getProfile();
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
  }

  Future<void> _fetchSessions() async {
    final sdk = ref.read(hubsightSdkProvider);
    if (sdk == null) return;

    setState(() => _isLoadingSessions = true);
    try {
      final sessions = await sdk.auth.listSessions();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.revokeSession, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(l10n.confirmRevokeSession),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
            tooltip: l10n.logout,
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. User Profile Card
            _buildProfileCard(l10n),
            const SizedBox(height: 18),

            // 2. Devices & Active Sessions
            _buildSessionsCard(l10n),
            const SizedBox(height: 18),

            // 3. Security Settings (Lock & Password)
            _buildSecurityCard(l10n),
            const SizedBox(height: 18),

            // 4. Push Notification Settings
            _buildPushSettingsCard(l10n),
            const SizedBox(height: 18),

            // 5. Server & Container Config Card
            _buildServerInfoCard(sdk, l10n),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE85D10)))
          : Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: const Icon(Icons.person, color: Color(0xFFE85D10), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile?.fullName.isNotEmpty == true ? _profile!.fullName : 'Administrator',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${_profile?.username ?? "admin"} • ${_profile?.role.toUpperCase() ?? "ADMIN"}',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const ChangePasswordDialog(),
                    );
                  },
                  icon: const Icon(Icons.key, size: 16, color: Color(0xFFE85D10)),
                  label: Text(
                    l10n.changePasswordTitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFE85D10), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSessionsCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.devices, color: Color(0xFFE85D10), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.sessionsTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF64748B)),
                onPressed: _fetchSessions,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.sessionsSubtitle,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          if (_isLoadingSessions)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Color(0xFFE85D10)),
            ))
          else if (_sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Không có phiên nào khác đang hoạt động',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sessions.length,
              separatorBuilder: (_, __) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final s = _sessions[index];
                return Row(
                  children: [
                    Icon(
                      s.clientType?.contains('mobile') == true
                          ? Icons.phone_iphone
                          : Icons.laptop,
                      color: s.isCurrent ? const Color(0xFF10B981) : const Color(0xFF64748B),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  s.deviceLabel ?? s.clientType ?? 'Thiết bị',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (s.isCurrent) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    l10n.currentSession,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'IP: ${s.ipAddress ?? "Unknown"} • ${s.geoCity ?? "Local"}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    if (!s.isCurrent)
                      TextButton(
                        onPressed: () => _handleRevokeSession(s, l10n),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        child: Text(l10n.revokeSession, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.shield_outlined, color: Color(0xFFE85D10), size: 20),
              SizedBox(width: 8),
              Text(
                'Bảo mật Ứng dụng',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSwitchRow(
            title: l10n.lockOnBackground,
            subtitle: l10n.lockOnBackgroundDesc,
            value: _lockOnBackground,
            onChanged: (v) {
              setState(() => _lockOnBackground = v);
              ref.read(biometricServiceProvider).setAppLockEnabled(v);
            },
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          _buildSwitchRow(
            title: l10n.biometricUnlock,
            subtitle: l10n.biometricUnlockDesc,
            value: _biometricUnlock,
            onChanged: (v) {
              setState(() => _biometricUnlock = v);
              ref.read(biometricServiceProvider).setBiometricEnabled(v);
            },
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          Text(
            l10n.lockTimeoutTitle,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
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
              const SizedBox(width: 8),
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
              const SizedBox(width: 8),
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
    );
  }

  Widget _buildPushSettingsCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_none, color: Color(0xFFE85D10), size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.pushSettingsTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildSwitchRow(
            title: l10n.pushFamily,
            subtitle: l10n.pushFamilyDesc,
            value: _pushFamily,
            onChanged: (v) {
              setState(() => _pushFamily = v);
              _syncPushPreferences();
            },
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          _buildSwitchRow(
            title: l10n.pushStranger,
            subtitle: l10n.pushStrangerDesc,
            value: _pushStranger,
            onChanged: (v) {
              setState(() => _pushStranger = v);
              _syncPushPreferences();
            },
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          _buildSwitchRow(
            title: l10n.pushSystem,
            subtitle: l10n.pushSystemDesc,
            value: _pushSystem,
            onChanged: (v) {
              setState(() => _pushSystem = v);
              _syncPushPreferences();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServerInfoCard(HubSightSDK? sdk, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.dns_rounded, color: Color(0xFFE85D10), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.serverConfigTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ServerConfigScreen(isInitialSetup: false),
                    ),
                  );
                },
                child: Text(
                  l10n.changeServer,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE85D10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            sdk?.config.urls.gatewayUrl ?? 'Chưa cấu hình',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          if (sdk != null) ...[
            const SizedBox(height: 2),
            Text(
              'Profile: ${sdk.config.metadata.name}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        CupertinoSwitch(
          value: value,
          activeTrackColor: const Color(0xFFE85D10),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTimeoutButton({
    required String key,
    required String label,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE85D10) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
