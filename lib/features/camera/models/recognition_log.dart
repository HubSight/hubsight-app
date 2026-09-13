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
      memberName: json['member_name']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      thumbnailUrl: json['thumbnail_url']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
