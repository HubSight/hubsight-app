import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/auth_models.dart';
import '../../core/network/api_client.dart';
import '../../core/services/biometric_service.dart';
import '../../core/storage/storage_service.dart';
import '../auth/app_lock_screen.dart';
import '../config/server_config_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _selectedTimezone = 'UTC+7 (Vietnam, Bangkok, Jakarta)';
  
  final List<String> _timezones = [
    'UTC+7 (Vietnam, Bangkok, Jakarta)',
    'UTC+8 (Singapore, Beijing, Taipei)',
    'UTC+9 (Tokyo, Seoul)',
    'UTC+0 (London, GMT)',
    'UTC-5 (New York, EST)',
    'UTC-8 (Los Angeles, PST)',
  ];

  // Push notification preferences (default enabled)
  bool _pushFamily = true;
  bool _pushStranger = true;
  bool _pushSystem = true;

  // Security preferences
  bool _lockOnBackground = false;
  bool _biometricUnlock = false;
  
  // Timeout: 'immediate' | '1min' | '5mins'
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
  }

  void _syncPushPreferences() {
    ref.read(apiClientProvider).updatePreferences(
      PushPreferences(
        family: _pushFamily,
        guest: _pushFamily,
        stranger: _pushStranger,
        system: _pushSystem,
      ),
    );
  }

  void _showTimezonePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.selectTimezone,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ..._timezones.map((tz) {
                  final isSelected = tz == _selectedTimezone;
                  return ListTile(
                    title: Text(
                      tz,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? const Color(0xFFE85D10) : const Color(0xFF0F172A),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Color(0xFFE85D10))
                        : null,
                    onTap: () {
                      setState(() => _selectedTimezone = tz);
                      ref.read(apiClientProvider).updateTimezone(tz);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            // Shield Icon in light orange container
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: const Icon(
                Icons.shield_outlined,
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
                    l10n.settingsTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.settingsSubtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF64748B)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card 1: App / Web Mode Info Badge
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2.0),
                    child: Icon(
                      Icons.smartphone_outlined,
                      color: Color(0xFF64748B),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appModeTitle,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.appModeDesc,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Card 2: Display Timezone Card
            Container(
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
                      const Icon(Icons.language, color: Color(0xFFE85D10), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.timezoneTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.timezoneDesc,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dropdown pill
                  InkWell(
                    onTap: _showTimezonePicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _selectedTimezone,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Card 3: Push Notification Settings Card
            Container(
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
                      const Icon(Icons.notifications_none_rounded, color: Color(0xFFE85D10), size: 18),
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
                  const SizedBox(height: 4),
                  Text(
                    l10n.pushSettingsSubtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Option 1: Người quen (Gia đình, Khách)
                  _buildPushSwitchTile(
                    title: l10n.pushFamily,
                    subtitle: l10n.pushFamilyDesc,
                    value: _pushFamily,
                    onChanged: (val) {
                      setState(() => _pushFamily = val);
                      _syncPushPreferences();
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),

                  // Option 2: Cảnh báo an ninh & Người lạ
                  _buildPushSwitchTile(
                    title: l10n.pushStranger,
                    subtitle: l10n.pushStrangerDesc,
                    value: _pushStranger,
                    onChanged: (val) {
                      setState(() => _pushStranger = val);
                      _syncPushPreferences();
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),

                  // Option 3: Thông báo hệ thống
                  _buildPushSwitchTile(
                    title: l10n.pushSystem,
                    subtitle: l10n.pushSystemDesc,
                    value: _pushSystem,
                    onChanged: (val) {
                      setState(() => _pushSystem = val);
                      _syncPushPreferences();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Card 4: Lock on Background Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.lockOnBackground,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.lockOnBackgroundDesc,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      CupertinoSwitch(
                        activeColor: const Color(0xFFE85D10),
                        value: _lockOnBackground,
                        onChanged: (val) async {
                          final bio = ref.read(biometricServiceProvider);
                          if (val) {
                            if (!bio.hasPin) {
                              // Set new PIN
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AppLockScreen(
                                    isCreatingPin: true,
                                    onUnlocked: () {
                                      Navigator.pop(context);
                                      setState(() => _lockOnBackground = true);
                                    },
                                  ),
                                ),
                              );
                            } else {
                              await bio.setAppLockEnabled(true);
                              setState(() => _lockOnBackground = true);
                            }
                          } else {
                            await bio.setAppLockEnabled(false);
                            setState(() => _lockOnBackground = false);
                          }
                        },
                      ),
                    ],
                  ),
                  if (_lockOnBackground) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AppLockScreen(
                              isCreatingPin: true,
                              onUnlocked: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã cập nhật mã PIN mới')),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Đổi mã PIN mở khóa',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE85D10),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFE85D10)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Card 5: Biometric Unlock Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2.0),
                    child: Icon(
                      Icons.fingerprint,
                      color: Color(0xFFE85D10),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.biometricUnlock,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.biometricUnlockDesc,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: CupertinoSwitch(
                      activeColor: const Color(0xFFE85D10),
                      value: _biometricUnlock,
                      onChanged: (val) async {
                        final bio = ref.read(biometricServiceProvider);
                        if (val) {
                          final canAuth = await bio.canCheckBiometrics();
                          if (!canAuth) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Thiết bị không hỗ trợ sinh trắc học')),
                              );
                            }
                            return;
                          }
                          final success = await bio.authenticate(
                            localizedReason: 'Xác thực để kích hoạt khóa sinh trắc học',
                          );
                          if (success) {
                            await bio.setBiometricEnabled(true);
                            setState(() => _biometricUnlock = true);
                          }
                        } else {
                          await bio.setBiometricEnabled(false);
                          setState(() => _biometricUnlock = false);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Card 6: Screen Lock Timeout Card
            Container(
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
                      const Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFF94A3B8),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.lockTimeoutTitle,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.lockTimeoutDesc,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF94A3B8),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Timeout Option Buttons
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
                      const SizedBox(width: 10),
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
                      const SizedBox(width: 10),
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

            const SizedBox(height: 14),

            // Card 7: Server Configuration Card
            Consumer(
              builder: (context, ref, child) {
                final storage = ref.watch(storageServiceProvider);
                final currentServer = storage.getServerUrl() ?? 'http://10.0.2.2:8088';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.dns_rounded, color: Color(0xFFE85D10), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.serverConfigTitle,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentServer,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
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
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE85D10),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPushSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: CupertinoSwitch(
            activeColor: const Color(0xFFE85D10),
            value: value,
            onChanged: onChanged,
          ),
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
      onTap: onTap ?? () => setState(() => _selectedTimeout = key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4A261) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFF4A261) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
