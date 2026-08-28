import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/socket_service.dart';
import 'models/notification_model.dart';

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

        // Demo sample notifications if backend is empty to showcase the exact design
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
          title: 'Test Push Notification',
          body: 'This is a test notification triggered from the UI. lúc 14:41:41',
          category: 'system',
          isRead: true,
          createdAt: now.subtract(const Duration(hours: 2)).toIso8601String(),
        ),
        NotificationItem(
          id: 'n2',
          type: 'push',
          title: 'Test Push Notification',
          body: 'This is a test notification triggered from the UI. lúc 14:23:14',
          category: 'system',
          isRead: true,
          createdAt: now.subtract(const Duration(hours: 2, minutes: 18)).toIso8601String(),
        ),
        NotificationItem(
          id: 'n3',
          type: 'push',
          title: 'Test Push Notification',
          body: 'This is a test notification triggered from the UI. lúc 14:00:15',
          category: 'system',
          isRead: true,
          createdAt: now.subtract(const Duration(hours: 2, minutes: 41)).toIso8601String(),
        ),
        NotificationItem(
          id: 'n4',
          type: 'push',
          title: 'Test Push Notification',
          body: 'This is a test notification triggered from the UI. lúc 13:55:42',
          category: 'system',
          isRead: true,
          createdAt: now.subtract(const Duration(hours: 3)).toIso8601String(),
        ),
        NotificationItem(
          id: 'n5',
          cameraId: 'cam_facetime',
          type: 'danger',
          title: 'Cảnh báo rủi ro: FIRE',
          body: 'Phát hiện FIRE tại camera Facetime HD Cam 25/08/2026 lúc 00:48:53',
          category: 'risk',
          isRead: false,
          createdAt: now.subtract(const Duration(days: 3)).toIso8601String(),
        ),
        NotificationItem(
          id: 'n6',
          cameraId: 'cam_facetime',
          type: 'danger',
          title: 'Cảnh báo rủi ro: SMOKE',
          body: 'Phát hiện SMOKE tại camera Facetime HD Cam 25/08/2026 lúc 00:48:51',
          category: 'risk',
          isRead: false,
          createdAt: now.subtract(const Duration(days: 3, minutes: 2)).toIso8601String(),
        ),
        NotificationItem(
          id: 'n7',
          cameraId: 'cam_facetime',
          type: 'fall',
          title: 'Cảnh báo: Phát hiện té ngã',
          body: 'Phát hiện té ngã tại camera Facetime HD Cam 25/08/2026 lúc 00:47:48',
          category: 'fall',
          isRead: false,
          createdAt: now.subtract(const Duration(days: 3, minutes: 3)).toIso8601String(),
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

  Future<void> _handleClearAll(AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAll),
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
            // Light orange bell icon container
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
            // Title and subtitle column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.notificationTitle,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
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
          // Filter Tabs & Delete Action Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

                // Delete All Button (Without Test Push button)
                InkWell(
                  onTap: _notifications.isEmpty ? null : () => _handleClearAll(l10n),
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
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Notifications List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item, AppLocalizations l10n) {
    final isDangerOrFall = item.category == 'risk' || item.category == 'fall' || item.type == 'danger';
    final hasCameraPlayback = item.cameraId != null || item.body.toLowerCase().contains('camera');
    final relativeTime = _formatRelativeTime(item.createdAt, l10n);

    return InkWell(
      onTap: () => _handleMarkRead(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isRead ? const Color(0xFFE2E8F0) : const Color(0xFFFED7AA),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading Round/Square Icon Badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDangerOrFall
                    ? Icons.notifications_none_rounded
                    : Icons.notifications_none_rounded,
                color: const Color(0xFF334155),
                size: 20,
              ),
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
                        child: Row(
                          children: [
                            if (isDangerOrFall) ...[
                              const Text('⚠️ ', style: TextStyle(fontSize: 13)),
                            ],
                            Flexible(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
                  const SizedBox(height: 5),

                  // Body Description
                  Text(
                    item.body,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                      height: 1.35,
                    ),
                  ),

                  // Action Link (Xem lại camera)
                  if (hasCameraPlayback) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.videocam_outlined,
                              size: 15,
                              color: Color(0xFFE85D10),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              l10n.viewPlayback,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE85D10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

