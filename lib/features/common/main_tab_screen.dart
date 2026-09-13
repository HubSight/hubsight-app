import 'dart:async';
import 'dart:ui';
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

/// Global provider for tracking whether the player is in fullscreen landscape mode.
final isFullScreenPlayerProvider = StateProvider<bool>((ref) => false);

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

  @override
  void didUpdateWidget(MainTabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(mainTabIndexProvider.notifier).state = widget.initialTab;
      });
    }
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
        _alertSub = sdk.relay.onAIAlert.listen((event) {
          if (mounted && (event.eventType == 'fall' || event.eventType == 'danger')) {
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
    final isFullscreen = ref.watch(isFullScreenPlayerProvider);
    final l10n = AppLocalizations.of(context)!;

    ref.listen<int>(mainTabIndexProvider, (previous, next) {
      if (next == 0) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        ref.read(isFullScreenPlayerProvider.notifier).state = false;
      }
    });

    const tabs = [
      PlaybackScreen(),
      DashboardScreen(),
      NotificationScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: context.bgAdaptive,
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: isFullscreen
          ? null
          : _buildNavigationDock(
              currentIndex: currentIndex,
              unreadCount: unreadCount,
              l10n: l10n,
            ),
    );
  }

  Widget _buildNavigationDock({
    required int currentIndex,
    required int unreadCount,
    required AppLocalizations l10n,
  }) {
    return SafeArea(
      top: false,
      bottom: true,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              key: const Key('main-navigation-dock'),
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? const Color(0xFF1B202A).withValues(alpha: 0.86)
                    : Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.isDarkMode
                        ? Colors.black.withValues(alpha: 0.45)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: context.isDarkMode
                        ? Colors.black.withValues(alpha: 0.20)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
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
    final inactiveColor = context.isDarkMode
        ? const Color(0xFF8E95A3)
        : const Color(0xFF6B7280);
    const activeColor = HubSightColors.primary;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('main-navigation-tab-$index'),
            onTap: () {
              if (!isSelected) {
                HapticFeedback.selectionClick();
                ref.read(mainTabIndexProvider.notifier).state = index;
              }
            },
            borderRadius: BorderRadius.circular(22),
            splashColor: HubSightColors.primary.withValues(alpha: 0.12),
            highlightColor: Colors.transparent,
            child: SizedBox(
              height: 56,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.06 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        if (isSelected)
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: HubSightColors.primary.withValues(
                                    alpha: context.isDarkMode ? 0.38 : 0.24,
                                  ),
                                  blurRadius: 14,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          switchInCurve: Curves.easeOutBack,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                          child: Icon(
                            isSelected ? activeIcon : inactiveIcon,
                            key: ValueKey(isSelected),
                            size: 22,
                            color: isSelected ? activeColor : inactiveColor,
                          ),
                        ),
                        if (badgeCount > 0)
                          Positioned(
                            top: -4,
                            right: -9,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              decoration: BoxDecoration(
                                color: HubSightColors.error,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: context.isDarkMode
                                      ? const Color(0xFF1B202A)
                                      : Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                badgeCount > 99 ? '99+' : '$badgeCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
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
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? activeColor : inactiveColor,
                      letterSpacing: isSelected ? -0.1 : -0.05,
                      height: 1.1,
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
      ),
    );
  }
}
