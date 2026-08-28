class CameraItem {
  final String id;
  final String name;
  final String host;
  final String brand;
  final bool isActive;
  final bool isStopped;
  final bool enableAi;
  final bool showBbox;

  CameraItem({
    required this.id,
    required this.name,
    this.host = '',
    this.brand = '',
    this.isActive = true,
    this.isStopped = false,
    this.enableAi = true,
    this.showBbox = true,
  });

  factory CameraItem.fromJson(Map<String, dynamic> json) {
    return CameraItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Camera',
      host: json['host'] ?? '',
      brand: json['brand'] ?? '',
      isActive: json['is_active'] ?? true,
      isStopped: json['is_stopped'] ?? false,
      enableAi: json['enable_ai'] ?? true,
      showBbox: json['show_bbox'] ?? true,
    );
  }
}

class Recording {
  final String id;
  final String cameraId;
  final String startAt;
  final String endAt;
  final int durationSeconds;
  final String filePath;
  final String? thumbnailPath;
  final int sizeBytes;
  final String createdAt;

  Recording({
    required this.id,
    required this.cameraId,
    required this.startAt,
    required this.endAt,
    required this.durationSeconds,
    required this.filePath,
    this.thumbnailPath,
    this.sizeBytes = 0,
    required this.createdAt,
  });

  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id']?.toString() ?? '',
      cameraId: json['camera_id']?.toString() ?? '',
      startAt: json['start_at'] ?? '',
      endAt: json['end_at'] ?? '',
      durationSeconds: json['duration_seconds'] ?? 0,
      filePath: json['file_path'] ?? '',
      thumbnailPath: json['thumbnail_path'],
      sizeBytes: json['size_bytes'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }

  String get eventType {
    final lower = filePath.toLowerCase();
    if (lower.contains('fire') || lower.contains('smoke') || lower.contains('danger') || lower.contains('weapon')) {
      return 'danger';
    }
    if (lower.contains('fall') || lower.contains('collapse') || lower.contains('anomaly')) {
      return 'fall';
    }
    if (lower.contains('stranger')) {
      return 'stranger';
    }
    return 'motion';
  }
}

