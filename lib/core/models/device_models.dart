class DeviceScanItem {
  final String ip;
  final int port;
  final String? brand;
  final String? name;
  final String? rtspUri;
  final String? onvifUri;

  DeviceScanItem({
    required this.ip,
    required this.port,
    this.brand,
    this.name,
    this.rtspUri,
    this.onvifUri,
  });

  factory DeviceScanItem.fromJson(Map<String, dynamic> json) {
    return DeviceScanItem(
      ip: json['ip'] ?? '',
      port: json['port'] ?? 554,
      brand: json['brand'],
      name: json['name'],
      rtspUri: json['rtsp_uri'],
      onvifUri: json['onvif_uri'],
    );
  }
}

class DeviceScanJob {
  final String id;
  final String status; // 'running', 'completed', 'failed'
  final List<DeviceScanItem> devices;

  DeviceScanJob({
    required this.id,
    required this.status,
    this.devices = const [],
  });

  factory DeviceScanJob.fromJson(Map<String, dynamic> json) {
    final list = json['devices'] as List<dynamic>? ?? [];
    return DeviceScanJob(
      id: json['id']?.toString() ?? '',
      status: json['status'] ?? 'completed',
      devices: list.map((e) => DeviceScanItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class RecognitionLog {
  final String id;
  final String cameraId;
  final String? memberId;
  final String? memberName;
  final double confidence;
  final String? thumbnailUrl;
  final String createdAt;

  RecognitionLog({
    required this.id,
    required this.cameraId,
    this.memberId,
    this.memberName,
    this.confidence = 0.0,
    this.thumbnailUrl,
    required this.createdAt,
  });

  factory RecognitionLog.fromJson(Map<String, dynamic> json) {
    return RecognitionLog(
      id: json['id']?.toString() ?? '',
      cameraId: json['camera_id']?.toString() ?? '',
      memberId: json['member_id']?.toString(),
      memberName: json['member_name'],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      thumbnailUrl: json['thumbnail_url'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

