import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/sdk_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../camera/playback_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../notifications/notification_screen.dart';
import '../settings/settings_screen.dart';

/// Global provider for controlling the currently active tab index.
final mainTabIndexProvider = StateProvider<int>((ref) => 0);

/// Global provider for tracking unread notification count badge.
final unreadNotificationCountProvider = StateProvider<int>((ref) => 0);

class MainTabScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const MainTabScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  ConsumerState<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends ConsumerState<MainTabScreen> {
  StreamSubscription? _alertSub;

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(mainTabIndexProvider.notifier).state = widget.initialTab;
      });
    }

    _initNotificationBadge();
  }

  void _initNotificationBadge() async {
    final sdk = ref.read(hubsightSdkProvider);
    if (sdk != null) {
      try {
        final res = await sdk.notifications.listNotifications();
        if (mounted) {
          ref.read(unreadNotificationCountProvider.notifier).state = res.unreadCount;
        }
      } catch (_) {}

      try {
        sdk.relay.connect();
        _alertSub = sdk.relay.onAIAlert.listen((_) {
          if (mounted) {
            ref.read(unreadNotificationCountProvider.notifier).update((count) => count + 1);
          }
        });
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainTabIndexProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final l10n = AppLocalizations.of(context)!;

    const tabs = [
      PlaybackScreen(),
      DashboardScreen(),
      NotificationScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: context.bgAdaptive,
      body: IndexedStack(
        index: currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.cardAdaptive,
          border: Border(
            top: BorderSide(
              color: context.borderAdaptive,
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: context.isDarkMode ? Colors.black26 : Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabItem(
                  index: 0,
                  currentIndex: currentIndex,
                  label: l10n.tabPlayback,
                  activeIcon: Icons.videocam_rounded,
                  inactiveIcon: Icons.videocam_outlined,
                ),
                _buildTabItem(
                  index: 1,
                  currentIndex: currentIndex,
                  label: l10n.tabDashboard,
                  activeIcon: Icons.grid_view_rounded,
                  inactiveIcon: Icons.grid_view_outlined,
                ),
                _buildTabItem(
                  index: 2,
                  currentIndex: currentIndex,
                  label: l10n.tabNotifications,
                  activeIcon: Icons.notifications_rounded,
                  inactiveIcon: Icons.notifications_none_rounded,
                  badgeCount: unreadCount,
                ),
                _buildTabItem(
                  index: 3,
                  currentIndex: currentIndex,
                  label: l10n.tabSettings,
                  activeIcon: Icons.tune_rounded,
                  inactiveIcon: Icons.tune_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required int currentIndex,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
    int badgeCount = 0,
  }) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!isSelected) {
              HapticFeedback.selectionClick();
              ref.read(mainTabIndexProvider.notifier).state = index;
            }
          },
          borderRadius: HubSightRadius.roundedXl,
          splashColor: HubSightColors.primary.withValues(alpha: 0.15),
          highlightColor: HubSightColors.primary.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with subtle active pill background & badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? HubSightColors.primary.withValues(alpha: 0.16)
                        : Colors.transparent,
                    borderRadius: HubSightRadius.roundedFull,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isSelected ? activeIcon : inactiveIcon,
                        size: 22,
                        color: isSelected
                            ? HubSightColors.primary
                            : context.textMutedAdaptive,
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          top: -4,
                          right: -10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                            decoration: BoxDecoration(
                              color: HubSightColors.error,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: context.cardAdaptive,
                                width: 1.5,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              badgeCount > 99 ? '99+' : '$badgeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // Tab label
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? HubSightColors.primary
                        : context.textMutedAdaptive,
                    letterSpacing: -0.1,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
