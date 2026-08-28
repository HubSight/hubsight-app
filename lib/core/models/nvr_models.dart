class NvrSystemMetrics {
  final double cpuUsagePercent;
  final double memoryAllocMb;
  final int uptimeSeconds;
  final int goroutines;
  final int numCpu;

  NvrSystemMetrics({
    this.cpuUsagePercent = 0.0,
    this.memoryAllocMb = 0.0,
    this.uptimeSeconds = 0,
    this.goroutines = 0,
    this.numCpu = 1,
  });

  factory NvrSystemMetrics.fromJson(Map<String, dynamic>? json) {
    if (json == null) return NvrSystemMetrics();
    return NvrSystemMetrics(
      cpuUsagePercent: (json['cpu_usage_percent'] as num?)?.toDouble() ?? 0.0,
      memoryAllocMb: (json['memory_alloc_mb'] as num?)?.toDouble() ?? 0.0,
      uptimeSeconds: json['uptime_seconds'] ?? 0,
      goroutines: json['goroutines'] ?? 0,
      numCpu: json['num_cpu'] ?? 1,
    );
  }
}

class NvrStorageMetrics {
  final int quotaBytes;
  final int usedBytes;
  final int freeBytes;
  final double usedPercentage;
  final int retentionDays;

  NvrStorageMetrics({
    this.quotaBytes = 0,
    this.usedBytes = 0,
    this.freeBytes = 0,
    this.usedPercentage = 0.0,
    this.retentionDays = 30,
  });

  factory NvrStorageMetrics.fromJson(Map<String, dynamic>? json) {
    if (json == null) return NvrStorageMetrics();
    return NvrStorageMetrics(
      quotaBytes: json['quota_bytes'] ?? 0,
      usedBytes: json['used_bytes'] ?? 0,
      freeBytes: json['free_bytes'] ?? 0,
      usedPercentage: (json['used_percentage'] as num?)?.toDouble() ?? 0.0,
      retentionDays: json['retention_days'] ?? 30,
    );
  }
}

class NvrCameraStatus {
  final String cameraId;
  final String name;
  final String host;
  final String status; // 'recording', 'stalled', 'disabled'
  final String rtspTransport;
  final String videoCodec;
  final String audioMode;
  final int segmentDuration;
  final String? latestSegmentAt;
  final int latestSegmentSize;
  final int totalSegments;

  NvrCameraStatus({
    required this.cameraId,
    required this.name,
    this.host = '',
    this.status = 'recording',
    this.rtspTransport = 'tcp',
    this.videoCodec = 'h264',
    this.audioMode = 'aac',
    this.segmentDuration = 60,
    this.latestSegmentAt,
    this.latestSegmentSize = 0,
    this.totalSegments = 0,
  });

  factory NvrCameraStatus.fromJson(Map<String, dynamic> json) {
    return NvrCameraStatus(
      cameraId: json['camera_id']?.toString() ?? '',
      name: json['name'] ?? '',
      host: json['host'] ?? '',
      status: json['status'] ?? 'recording',
      rtspTransport: json['rtsp_transport'] ?? 'tcp',
      videoCodec: json['video_codec'] ?? 'h264',
      audioMode: json['audio_mode'] ?? 'aac',
      segmentDuration: json['segment_duration'] ?? 60,
      latestSegmentAt: json['latest_segment_at'],
      latestSegmentSize: json['latest_segment_size'] ?? 0,
      totalSegments: json['total_segments'] ?? 0,
    );
  }
}

class NvrStatusResponse {
  final String status;
  final bool isGlobalEnabled;
  final NvrSystemMetrics system;
  final NvrStorageMetrics storage;
  final int activeLiveStreamsCount;
  final List<NvrCameraStatus> cameras;

  NvrStatusResponse({
    this.status = 'healthy',
    this.isGlobalEnabled = true,
    required this.system,
    required this.storage,
    this.activeLiveStreamsCount = 0,
    this.cameras = const [],
  });

  factory NvrStatusResponse.fromJson(Map<String, dynamic> json) {
    final cams = (json['cameras'] as List<dynamic>? ?? [])
        .map((e) => NvrCameraStatus.fromJson(e as Map<String, dynamic>))
        .toList();
    return NvrStatusResponse(
      status: json['status'] ?? 'healthy',
      isGlobalEnabled: json['is_global_enabled'] ?? true,
      system: NvrSystemMetrics.fromJson(json['system']),
      storage: NvrStorageMetrics.fromJson(json['storage']),
      activeLiveStreamsCount: json['active_live_streams_count'] ?? 0,
      cameras: cams,
    );
  }
}

