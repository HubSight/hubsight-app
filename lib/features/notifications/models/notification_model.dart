class NotificationItem {
  final String id;
  final String? cameraId;
  final String type;
  final String title;
  final String body;
  final String category;
  final String? memberId;
  final String? thumbnailUrl;
  final bool isRead;
  final String createdAt;

  NotificationItem({
    required this.id,
    this.cameraId,
    required this.type,
    required this.title,
    required this.body,
    this.category = 'system',
    this.memberId,
    this.thumbnailUrl,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      cameraId: json['camera_id']?.toString(),
      type: json['type'] ?? 'system',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      category: json['category'] ?? 'system',
      memberId: json['member_id']?.toString(),
      thumbnailUrl: json['thumbnail_url'],
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      cameraId: cameraId,
      type: type,
      title: title,
      body: body,
      category: category,
      memberId: memberId,
      thumbnailUrl: thumbnailUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

class NotificationResponse {
  final int unreadCount;
  final List<NotificationItem> notifications;

  NotificationResponse({
    required this.unreadCount,
    required this.notifications,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final list = json['notifications'] as List<dynamic>? ?? [];
    return NotificationResponse(
      unreadCount: json['unread_count'] ?? 0,
      notifications: list.map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

