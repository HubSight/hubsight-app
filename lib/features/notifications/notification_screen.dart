import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cctv_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';
import '../../core/network/sdk_provider.dart';
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
  String _filter = 'all'; // 'all' | 'unread'
  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();

    final sdk = ref.read(hubsightSdkProvider);
    if (sdk != null) {
      sdk.relay.connect();
      _socketSub = sdk.relay.onAIAlert.listen((data) {
        if (!mounted) return;
        _fetchNotifications();
      });
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final sdk = ref.read(hubsightSdkProvider);
      if (sdk != null) {
        final response = await sdk.notifications.listNotifications();
        if (mounted) {
          setState(() {
            _notifications = response.items;
            _unreadCount = response.unreadCount;
            _isLoading = false;
          });

          if (_notifications.isEmpty) {
            _loadSampleNotifications();
          }
        }
      } else {
        if (mounted) {
          _loadSampleNotifications();
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        _loadSampleNotifications();
        setState(() => _isLoading = false);
      }
    }
  }

  void _loadSampleNotifications() {
    final now = DateTime.now();
    setState(() {
      _notifications = [
        AppNotification(
          id: 'n1',
          cameraId: '',
          type: 'push',
          title: 'Thông báo hệ thống',
          body: 'Hệ thống NVR đang hoạt động ổn định. Đã ghi lại 24 bản ghi.',
          category: 'system',
          isRead: true,
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        AppNotification(
          id: 'n2',
          cameraId: 'cam_facetime',
          type: 'family',
          title: 'Nhận diện thành viên: Anh Quốc',
          body: 'Đã nhận diện thành viên gia đình Anh Quốc tại camera Facetime HD Cam',
          category: 'family',
          isRead: true,
          createdAt: now.subtract(const Duration(hours: 2, minutes: 15)),
        ),
        AppNotification(
          id: 'n3',
          cameraId: 'cam_facetime',
          type: 'danger',
          title: 'Cảnh báo rủi ro: FIRE',
          body: 'Phát hiện FIRE tại camera Facetime HD Cam',
          category: 'risk',
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
        AppNotification(
          id: 'n4',
          cameraId: 'cam_facetime',
          type: 'fall',
          title: 'Cảnh báo: Phát hiện té ngã',
          body: 'Phát hiện tư thế té ngã tại camera Facetime HD Cam',
          category: 'fall',
          isRead: false,
          createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        ),
        AppNotification(
          id: 'n5',
          cameraId: 'cam_facetime',
          type: 'stranger',
          title: 'Cảnh báo: Người lạ mặt',
          body: 'Phát hiện người lạ mặt xuất hiện trước camera Facetime HD Cam',
          category: 'stranger',
          isRead: false,
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ];
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    });
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

  Future<void> _handleDelete(String id) async {
    setState(() {
      final removed = _notifications.firstWhere((n) => n.id == id, orElse: () => _notifications.first);
      if (!removed.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
      }
      _notifications.removeWhere((n) => n.id == id);
    });
    await ref.read(hubsightSdkProvider)?.notifications.deleteNotification(id);
  }

  Future<void> _handleClearAll(AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: HubSightColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: HubSightRadius.roundedCard,
          side: const BorderSide(color: HubSightColors.borderDark),
        ),
        title: Text(l10n.deleteAll, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: HubSightColors.textPrimary)),
        content: Text(l10n.confirmDeleteAll, style: const TextStyle(color: HubSightColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: const TextStyle(color: HubSightColors.textMuted)),
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

    if (confirm == true) {
      final listCopy = List<AppNotification>.from(_notifications);
      setState(() {
        _notifications.clear();
        _unreadCount = 0;
      });
      final sdk = ref.read(hubsightSdkProvider);
      if (sdk != null) {
        for (var item in listCopy) {
          await sdk.notifications.deleteNotification(item.id);
        }
      }
    }
  }

  void _handleItemClick(AppNotification item) {
    if (!item.isRead) {
      _handleMarkRead(item);
    }
    if (item.cameraId.isNotEmpty || item.body.toLowerCase().contains('camera')) {
      Navigator.pop(context);
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
      backgroundColor: HubSightColors.bgDark,
      appBar: AppBar(
        backgroundColor: HubSightColors.cardDark,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: HubSightColors.borderDark, width: 1),
        ),
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            // Bell icon container
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: HubSightColors.surfaceDark,
                borderRadius: HubSightRadius.roundedXl,
                border: Border.all(color: HubSightColors.borderDark),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: HubSightColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.notificationTitle,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: HubSightColors.textPrimary,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: HubSightColors.error,
                            borderRadius: HubSightRadius.roundedXl,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.notificationSubtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: HubSightColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: HubSightColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs & Actions Bar
          Container(
            color: HubSightColors.cardDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Filter Tabs (Tất cả, Chưa đọc)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: HubSightColors.surfaceDark,
                    borderRadius: HubSightRadius.roundedXl,
                    border: Border.all(color: HubSightColors.borderDark),
                  ),
                  child: Row(
                    children: [
                      _buildFilterTab(
                        key: 'all',
                        label: l10n.filterAll(totalCount),
                        isSelected: _filter == 'all',
                      ),
                      _buildFilterTab(
                        key: 'unread',
                        label: l10n.filterUnread(unreadCount),
                        isSelected: _filter == 'unread',
                      ),
                    ],
                  ),
                ),

                // Actions: Mark All Read & Clear All
                Row(
                  children: [
                    if (unreadCount > 0)
                      InkWell(
                        onTap: _handleMarkAllRead,
                        borderRadius: HubSightRadius.roundedXl,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              Icon(Icons.done_all_rounded, size: 16, color: HubSightColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Đã đọc hết',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: HubSightColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_notifications.isNotEmpty)
                      InkWell(
                        onTap: () => _handleClearAll(l10n),
                        borderRadius: HubSightRadius.roundedXl,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded, size: 16, color: HubSightColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                l10n.deleteAll,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: HubSightColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: HubSightColors.borderDark),

          // Notifications List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: HubSightColors.primary))
                : _filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_off_outlined, size: 48, color: HubSightColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              l10n.noNotifications,
                              style: const TextStyle(color: HubSightColors.textMuted, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchNotifications,
                        color: HubSightColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _filteredList.length,
                          itemBuilder: (context, index) {
                            final item = _filteredList[index];
                            return _buildNotificationCard(item, l10n);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String key,
    required String label,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() => _filter = key),
      borderRadius: HubSightRadius.roundedXl,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? HubSightColors.surfaceElevated : Colors.transparent,
          borderRadius: HubSightRadius.roundedXl,
          border: isSelected ? Border.all(color: HubSightColors.borderDark) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? HubSightColors.primaryLight : HubSightColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification item, AppLocalizations l10n) {
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
      onDismissed: (_) => _handleDelete(item.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: HubSightColors.errorBg,
          borderRadius: HubSightRadius.roundedCard,
        ),
        child: const Icon(Icons.delete_outline, color: HubSightColors.errorText, size: 24),
      ),
      child: InkWell(
        onTap: () => _handleItemClick(item),
        borderRadius: HubSightRadius.roundedCard,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: HubSightColors.cardDark,
            borderRadius: HubSightRadius.roundedCard,
            border: Border.all(
              color: item.isRead ? HubSightColors.borderDark : categoryColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: HubSightRadius.roundedCard,
            child: Stack(
              children: [
                // Left stripe for unread notifications
                if (!item.isRead)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 3,
                    child: Container(color: categoryColor),
                  ),

                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!item.isRead) const SizedBox(width: 4),

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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: !item.isRead ? FontWeight.bold : FontWeight.w600,
                                      color: HubSightColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  relativeTime,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: HubSightColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Body Description
                            Text(
                              item.body,
                              style: const TextStyle(
                                fontSize: 12,
                                color: HubSightColors.textSecondary,
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
                        icon: const Icon(Icons.close_rounded, size: 16, color: HubSightColors.textMuted),
                        onPressed: () => _handleDelete(item.id),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
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
