class StreamConnection {
  final String id;
  final String cameraId;
  final int index;
  final String purpose; // 'cv' | 'nvr' | 'live'
  final String streamName;
  final String sourceUrl;
  final int activeUsers;
  final int maxUsers;
  final String createdAt;
  final String lastUsedAt;
  final String status; // 'active' | 'idle' | 'error'

  StreamConnection({
    required this.id,
    required this.cameraId,
    this.index = 0,
    this.purpose = 'live',
    required this.streamName,
    this.sourceUrl = '',
    this.activeUsers = 0,
    this.maxUsers = 10,
    required this.createdAt,
    required this.lastUsedAt,
    this.status = 'active',
  });

  factory StreamConnection.fromJson(Map<String, dynamic> json) {
    return StreamConnection(
      id: json['id']?.toString() ?? '',
      cameraId: json['camera_id']?.toString() ?? '',
      index: json['index'] ?? 0,
      purpose: json['purpose'] ?? 'live',
      streamName: json['stream_name'] ?? '',
      sourceUrl: json['source_url'] ?? '',
      activeUsers: json['active_users'] ?? 0,
      maxUsers: json['max_users'] ?? 10,
      createdAt: json['created_at'] ?? '',
      lastUsedAt: json['last_used_at'] ?? '',
      status: json['status'] ?? 'active',
    );
  }
}

class CameraPool {
  final String cameraId;
  final String cameraName;
  final String host;
  final bool isActive;
  final bool enableAi;
  final StreamConnection? cvConnection;
  final StreamConnection? nvrConnection;
  final List<StreamConnection> liveStreams;

  CameraPool({
    required this.cameraId,
    required this.cameraName,
    this.host = '',
    this.isActive = true,
    this.enableAi = true,
    this.cvConnection,
    this.nvrConnection,
    this.liveStreams = const [],
  });

  factory CameraPool.fromJson(Map<String, dynamic> json) {
    List<StreamConnection> liveList = [];
    final livePool = json['live_pool'];
    if (livePool is Map) {
      livePool.forEach((key, val) {
        if (val is Map<String, dynamic>) {
          liveList.add(StreamConnection.fromJson(val));
        }
      });
    } else if (livePool is List) {
      liveList = livePool.map((e) => StreamConnection.fromJson(e as Map<String, dynamic>)).toList();
    }

    return CameraPool(
      cameraId: json['camera_id']?.toString() ?? '',
      cameraName: json['camera_name'] ?? '',
      host: json['host'] ?? '',
      isActive: json['is_active'] ?? true,
      enableAi: json['enable_ai'] ?? true,
      cvConnection: json['cv_connection'] != null
          ? StreamConnection.fromJson(json['cv_connection'] as Map<String, dynamic>)
          : null,
      nvrConnection: json['nvr_connection'] != null
          ? StreamConnection.fromJson(json['nvr_connection'] as Map<String, dynamic>)
          : null,
      liveStreams: liveList,
    );
  }
}

class PoolStatusSummary {
  final int totalCameras;
  final int activeCameras;
  final int totalCvStreams;
  final int totalNvrStreams;
  final int totalLiveStreams;
  final int totalActiveViewers;
  final List<CameraPool> cameras;

  PoolStatusSummary({
    this.totalCameras = 0,
    this.activeCameras = 0,
    this.totalCvStreams = 0,
    this.totalNvrStreams = 0,
    this.totalLiveStreams = 0,
    this.totalActiveViewers = 0,
    this.cameras = const [],
  });

  factory PoolStatusSummary.fromJson(Map<String, dynamic> json) {
    final cams = (json['cameras'] as List<dynamic>? ?? [])
        .map((e) => CameraPool.fromJson(e as Map<String, dynamic>))
        .toList();
    return PoolStatusSummary(
      totalCameras: json['total_cameras'] ?? 0,
      activeCameras: json['active_cameras'] ?? 0,
      totalCvStreams: json['total_cv_streams'] ?? 0,
      totalNvrStreams: json['total_nvr_streams'] ?? 0,
      totalLiveStreams: json['total_live_streams'] ?? 0,
      totalActiveViewers: json['total_active_viewers'] ?? 0,
      cameras: cams,
    );
  }
}

