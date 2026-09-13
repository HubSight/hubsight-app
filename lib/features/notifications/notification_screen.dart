import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hubsight_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';
import '../../core/localization/error_localizer.dart';
import '../../core/network/sdk_provider.dart';
import '../common/main_tab_screen.dart';
import '../../core/theme/app_theme.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  bool _isClearingAll = false;
  String _filter = 'all'; // 'all' | 'unread'
  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();

    final sdk = ref.read(hubsightSdkProvider);
    if (sdk != null) {
      sdk.relay.connect();
      _socketSub = sdk.relay.onAIAlert.listen((event) {
        if (!mounted) return;
        if (event.eventType == 'fall' || event.eventType == 'danger') {
          _fetchNotifications();
        }
      });
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final sdk = ref.read(hubsightSdkProvider);
      if (sdk == null) {
        if (mounted) {
          setState(() {
            _notifications = [];
            _unreadCount = 0;
            _isLoading = false;
          });
        }
        return;
      }

      final response = await sdk.notifications.listNotifications();
      if (mounted) {
        setState(() {
          _notifications = response.items;
          _unreadCount = response.unreadCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e);
      }
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppErrorLocalizer.localize(error, l10n)),
          backgroundColor: HubSightColors.error,
        ),
      );
  }

  Future<void> _handleMarkRead(AppNotification item) async {
    if (item.isRead) return;
    setState(() {
      _notifications = _notifications.map((n) {
        if (n.id == item.id) return n.copyWith(isRead: true);
        return n;
      }).toList();
      _unreadCount = (_unreadCount - 1).clamp(0, 999);
    });
    await ref.read(hubsightSdkProvider)?.notifications.markAsRead(item.id);
  }

  Future<void> _handleMarkAllRead() async {
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
    });
    await ref.read(hubsightSdkProvider)?.notifications.markAllAsRead();
  }

  Future<bool> _deleteNotificationFromServer(String id) async {
    final sdk = ref.read(hubsightSdkProvider);
    if (sdk == null) {
      _showError(StateError('HubSight SDK is not initialized'));
      return false;
    }

    try {
      await sdk.notifications.deleteNotification(id);
      return true;
    } catch (e) {
      debugPrint('Failed to delete notification $id: $e');
      _showError(e);
      return false;
    }
  }

  void _removeNotificationLocally(AppNotification item) {
    if (!mounted || !_notifications.any((n) => n.id == item.id)) return;
    setState(() {
      _notifications.removeWhere((n) => n.id == item.id);
      if (!item.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
      }
    });
  }

  Future<List<String>> _loadAllNotificationIds(HubSightSDK sdk) async {
    const pageSize = 100;
    final ids = <String>{};
    var fetchedItemCount = 0;
    var page = 1;

    while (true) {
      final response = await sdk.notifications.listNotifications(
        page: page,
        limit: pageSize,
      );
      fetchedItemCount += response.items.length;
      ids.addAll(response.items.map((item) => item.id));

      if (fetchedItemCount >= response.total || response.items.length < pageSize) {
        return ids.toList();
      }
      page++;
    }
  }

  Future<void> _handleClearAll(AppLocalizations l10n) async {
    if (_isClearingAll) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardAdaptive,
        shape: RoundedRectangleBorder(
          borderRadius: HubSightRadius.roundedCard,
          side: BorderSide(color: context.borderAdaptive),
        ),
        title: Text(l10n.deleteAll, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimaryAdaptive)),
        content: Text(l10n.confirmDeleteAll, style: TextStyle(color: context.textSecondaryAdaptive)),
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
            child: Text(l10n.confirmDelete),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted || _isClearingAll) return;

    final sdk = ref.read(hubsightSdkProvider);
    if (sdk == null) {
      _showError(StateError('HubSight SDK is not initialized'));
      return;
    }

    setState(() => _isClearingAll = true);
    try {
      final ids = await _loadAllNotificationIds(sdk);
      if (ids.isNotEmpty) {
        await sdk.notifications.deleteNotifications(ids);
      }
      if (mounted) {
        setState(() {
          _notifications.clear();
          _unreadCount = 0;
        });
        ref.read(unreadNotificationCountProvider.notifier).state = 0;
      }
    } catch (e) {
      debugPrint('Failed to clear notifications: $e');
      _showError(e);
      await _fetchNotifications();
    } finally {
      if (mounted) {
        setState(() => _isClearingAll = false);
      }
    }
  }

  void _handleItemClick(AppNotification item) {
    if (!item.isRead) {
      _handleMarkRead(item);
    }
    if (item.cameraId.isNotEmpty || item.body.toLowerCase().contains('camera')) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        ref.read(mainTabIndexProvider.notifier).state = 0;
      }
    }
  }

  String _formatRelativeTime(DateTime date, AppLocalizations l10n) {
    final diff = DateTime.now().difference(date);

    if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return l10n.timeMonthsAgo(months);
    } else if (diff.inDays > 0) {
      return l10n.timeDaysAgo(diff.inDays);
    } else if (diff.inHours > 0) {
      return l10n.timeHoursAgo(diff.inHours);
    } else if (diff.inMinutes > 0) {
      return l10n.timeMinutesAgo(diff.inMinutes);
    } else {
      return l10n.timeJustNow;
    }
  }

  List<AppNotification> get _filteredList {
    if (_filter == 'unread') {
      return _notifications.where((n) => !n.isRead).toList();
    }
    return _notifications;
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalCount = _notifications.length;
    final unreadCount = _unreadCount;

    return Scaffold(
      backgroundColor: context.bgAdaptive,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: HubSightGradients.accentHeaderAdaptive(context),
            boxShadow: [
              BoxShadow(
                color: HubSightColors.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.notificationTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.4,
                color: Colors.white,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: HubSightRadius.roundedXl,
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: HubSightColors.primary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 22),
              tooltip: 'Đã đọc hết',
              onPressed: () {
                HapticFeedback.lightImpact();
                _handleMarkAllRead();
              },
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: _isClearingAll
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 22),
              tooltip: l10n.deleteAll,
              onPressed: _isClearingAll
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      _handleClearAll(l10n);
                    },
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
            tooltip: l10n.loading,
            onPressed: () {
              HapticFeedback.lightImpact();
              _fetchNotifications();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs (Segmented Control)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: context.surfaceAdaptive,
                borderRadius: HubSightRadius.roundedXl,
                border: Border.all(color: context.borderAdaptive),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterTab(
                      key: 'all',
                      label: l10n.filterAll(totalCount),
                      isSelected: _filter == 'all',
                    ),
                  ),
                  Expanded(
                    child: _buildFilterTab(
                      key: 'unread',
                      label: l10n.filterUnread(unreadCount),
                      isSelected: _filter == 'unread',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: context.borderAdaptive),

          // Notifications List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchNotifications,
              color: HubSightColors.primary,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: HubSightColors.primary))
                  : _filteredList.isEmpty
                      ? _buildEmptyState(l10n)
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: _filteredList.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            thickness: 1,
                            color: context.borderAdaptive,
                          ),
                          itemBuilder: (context, index) {
                            final item = _filteredList[index];
                            return _buildNotificationItem(item, l10n);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _filter == 'unread' ? Icons.mark_email_read_outlined : Icons.notifications_none_rounded,
              size: 56,
              color: context.textMutedAdaptive,
            ),
            const SizedBox(height: 16),
            Text(
              _filter == 'unread' ? 'Không có thông báo chưa đọc' : l10n.noNotifications,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryAdaptive,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _filter == 'unread'
                  ? 'Bạn đã xem tất cả các cảnh báo an ninh'
                  : 'Các cảnh báo an ninh và sự kiện AI sẽ hiển thị ở đây',
              style: TextStyle(
                fontSize: 12.5,
                color: context.textMutedAdaptive,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab({
    required String key,
    required String label,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filter = key);
      },
      borderRadius: HubSightRadius.roundedXl,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (context.isDarkMode ? context.surfaceElevatedAdaptive : Colors.white)
              : Colors.transparent,
          borderRadius: HubSightRadius.roundedXl,
          border: isSelected ? Border.all(color: context.borderAdaptive) : null,
          boxShadow: isSelected && !context.isDarkMode
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? HubSightColors.primary : context.textMutedAdaptive,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification item, AppLocalizations l10n) {
    final isFamily = item.category == 'family' || item.type == 'family';
    final isGuest = item.category == 'guest' || item.type == 'guest';
    final isDanger = item.category == 'risk' || item.category == 'fall' || item.type == 'danger' || item.type == 'fall' || item.category == 'stranger';
    final hasCameraPlayback = item.cameraId.isNotEmpty || item.body.toLowerCase().contains('camera');
    final relativeTime = _formatRelativeTime(item.createdAt, l10n);

    Color categoryColor;
    Color categoryBg;
    IconData categoryIcon;

    if (isFamily) {
      categoryColor = const Color(0xFF10B981);
      categoryBg = const Color(0x2610B981);
      categoryIcon = Icons.verified_user_rounded;
    } else if (isGuest) {
      categoryColor = const Color(0xFF38BDF8);
      categoryBg = const Color(0x2638BDF8);
      categoryIcon = Icons.handshake_outlined;
    } else if (isDanger) {
      categoryColor = HubSightColors.error;
      categoryBg = HubSightColors.errorBg;
      categoryIcon = Icons.warning_amber_rounded;
    } else {
      categoryColor = HubSightColors.primary;
      categoryBg = HubSightColors.primaryBg;
      categoryIcon = Icons.notifications_none_rounded;
    }

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _deleteNotificationFromServer(item.id),
      onDismissed: (_) => _removeNotificationLocally(item),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: HubSightColors.errorBg,
        child: const Icon(Icons.delete_outline, color: HubSightColors.errorText, size: 24),
      ),
      child: InkWell(
        onTap: () => _handleItemClick(item),
        child: Container(
          color: !item.isRead
              ? context.surfaceAdaptive.withValues(alpha: 0.5)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading category icon badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: categoryBg,
                  borderRadius: HubSightRadius.roundedXl,
                  border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
                ),
                child: Icon(categoryIcon, color: categoryColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Content Area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Time Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (!item.isRead) ...[
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: categoryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: !item.isRead ? FontWeight.bold : FontWeight.w600,
                              color: context.textPrimaryAdaptive,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          relativeTime,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: !item.isRead ? FontWeight.bold : FontWeight.normal,
                            color: !item.isRead ? categoryColor : context.textMutedAdaptive,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Body Description
                    Text(
                      item.body,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondaryAdaptive,
                        height: 1.35,
                      ),
                    ),

                    // Action Link (Xem lại camera)
                    if (hasCameraPlayback) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam_outlined, size: 14, color: HubSightColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            l10n.viewPlayback,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: HubSightColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Delete action icon
              IconButton(
                icon: Icon(Icons.close_rounded, size: 16, color: context.textMutedAdaptive),
                onPressed: () async {
                  final deleted = await _deleteNotificationFromServer(item.id);
                  if (deleted) _removeNotificationLocally(item);
                },
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
