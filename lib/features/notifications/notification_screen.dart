import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/socket_service.dart';
import 'models/notification_model.dart';
import '../camera/playback_screen.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String _filter = 'all'; // 'all' | 'unread'
  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();

    // Listen for real-time notifications via Socket.IO
    final socketService = ref.read(socketServiceProvider);
    socketService.connect();
    _socketSub = socketService.onNotification.listen((data) {
      if (!mounted) return;
      final newNotif = NotificationItem.fromJson(data);
      setState(() {
        _notifications.removeWhere((n) => n.id == newNotif.id);
        _notifications.insert(0, newNotif);
        _unreadCount++;
      });
    });
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await ref.read(apiClientProvider).getNotifications();
      if (mounted) {
        setState(() {
          _notifications = response.notifications;
          _unreadCount = response.unreadCount;
          _isLoading = false;
        });

        if (_notifications.isEmpty) {
          _loadSampleNotifications();
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
        NotificationItem(
          id: 'n1',
          type: 'push',
          title: 'Thông báo hệ thống',
          body: 'Hệ thống NVR đang hoạt động ổn định. Đã ghi lại 24 bản ghi.',
          category: 'system',
          isRead: true,
          createdAt: now.subtract(const Duration(hours: 1)).toIso8601String(),
        ),
        NotificationItem(
          id: 'n2',
          cameraId: 'cam_facetime',
          type: 'family',
          title: 'Nhận diện thành viên: Anh Quốc',
          body: 'Đã nhận diện thành viên gia đình Anh Quốc tại camera Facetime HD Cam',
          category: 'family',
          isRead: true,
          createdAt: now.subtract(const Duration(hours: 2, minutes: 15)).toIso8601String(),
        ),
        NotificationItem(
          id: 'n3',
          cameraId: 'cam_facetime',
          type: 'danger',
          title: 'Cảnh báo rủi ro: FIRE',
          body: 'Phát hiện FIRE tại camera Facetime HD Cam',
          category: 'risk',
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 3)).toIso8601String(),
        ),
        NotificationItem(
          id: 'n4',
          cameraId: 'cam_facetime',
          type: 'fall',
          title: 'Cảnh báo: Phát hiện té ngã',
          body: 'Phát hiện tư thế té ngã tại camera Facetime HD Cam',
          category: 'fall',
          isRead: false,
          createdAt: now.subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
        ),
        NotificationItem(
          id: 'n5',
          cameraId: 'cam_facetime',
          type: 'stranger',
          title: 'Cảnh báo: Người lạ mặt',
          body: 'Phát hiện người lạ mặt xuất hiện trước camera Facetime HD Cam',
          category: 'stranger',
          isRead: false,
          createdAt: now.subtract(const Duration(days: 2)).toIso8601String(),
        ),
      ];
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    });
  }

  Future<void> _handleMarkRead(NotificationItem item) async {
    if (item.isRead) return;
    setState(() {
      _notifications = _notifications.map((n) {
        if (n.id == item.id) return n.copyWith(isRead: true);
        return n;
      }).toList();
      _unreadCount = (_unreadCount - 1).clamp(0, 999);
    });
    await ref.read(apiClientProvider).markNotificationRead(item.id);
  }

  Future<void> _handleMarkAllRead() async {
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
    });
    await ref.read(apiClientProvider).markAllNotificationsRead();
  }

  Future<void> _handleDelete(String id) async {
    setState(() {
      final removed = _notifications.firstWhere((n) => n.id == id, orElse: () => _notifications.first);
      if (!removed.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
      }
      _notifications.removeWhere((n) => n.id == id);
    });
    await ref.read(apiClientProvider).deleteNotification(id);
  }

  Future<void> _handleClearAll(AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteAll, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(l10n.confirmDeleteAll),
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
            child: Text(l10n.confirmDelete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _notifications.clear();
        _unreadCount = 0;
      });
      await ref.read(apiClientProvider).clearAllNotifications();
    }
  }

  void _handleItemClick(NotificationItem item) {
    if (!item.isRead) {
      _handleMarkRead(item);
    }
    if (item.cameraId != null || item.body.toLowerCase().contains('camera')) {
      Navigator.pop(context);
    }
  }

  String _formatRelativeTime(String isoString, AppLocalizations l10n) {
    final date = DateTime.tryParse(isoString);
    if (date == null) return '';
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

  List<NotificationItem> get _filteredList {
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            // Bell icon container
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFFE85D10),
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
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
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
                      color: Color(0xFF64748B),
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
            icon: const Icon(Icons.close, color: Color(0xFF64748B)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs & Actions Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Filter Tabs (Tất cả, Chưa đọc)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
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
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: const [
                              Icon(Icons.done_all_rounded, size: 16, color: Color(0xFFE85D10)),
                              SizedBox(width: 4),
                              Text(
                                'Đã đọc hết',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE85D10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_notifications.isNotEmpty)
                      InkWell(
                        onTap: () => _handleClearAll(l10n),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                l10n.deleteAll,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
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
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Notifications List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE85D10)))
                : _filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              l10n.noNotifications,
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchNotifications,
                        color: const Color(0xFFE85D10),
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
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item, AppLocalizations l10n) {
    final isFamily = item.category == 'family' || item.type == 'family';
    final isGuest = item.category == 'guest' || item.type == 'guest';
    final isDanger = item.category == 'risk' || item.category == 'fall' || item.type == 'danger' || item.type == 'fall' || item.category == 'stranger';
    final hasCameraPlayback = item.cameraId != null || item.body.toLowerCase().contains('camera');
    final relativeTime = _formatRelativeTime(item.createdAt, l10n);

    Color categoryColor;
    Color categoryBg;
    IconData categoryIcon;

    if (isFamily) {
      categoryColor = const Color(0xFF10B981);
      categoryBg = const Color(0xFFECFDF5);
      categoryIcon = Icons.verified_user_rounded;
    } else if (isGuest) {
      categoryColor = const Color(0xFF3B82F6);
      categoryBg = const Color(0xFFEFF6FF);
      categoryIcon = Icons.handshake_outlined;
    } else if (isDanger) {
      categoryColor = const Color(0xFFEF4444);
      categoryBg = const Color(0xFFFEF2F2);
      categoryIcon = Icons.warning_amber_rounded;
    } else {
      categoryColor = const Color(0xFFE85D10);
      categoryBg = const Color(0xFFFFF7ED);
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
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      child: InkWell(
        onTap: () => _handleItemClick(item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead ? const Color(0xFFE2E8F0) : categoryColor.withOpacity(0.5),
              width: item.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Left stripe for unread notifications
                if (!item.isRead)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 4,
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
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: categoryColor.withOpacity(0.2)),
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
                                      color: const Color(0xFF0F172A),
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
                                    color: Color(0xFF94A3B8),
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
                                color: Color(0xFF475569),
                                height: 1.35,
                              ),
                            ),

                            // Action Link (Xem lại camera)
                            if (hasCameraPlayback) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.videocam_outlined, size: 14, color: Color(0xFFE85D10)),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.viewPlayback,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE85D10),
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
                        icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFCBD5E1)),
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
