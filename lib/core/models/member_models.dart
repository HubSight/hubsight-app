class FaceItem {
  final String id;
  final String memberId;
  final String sampleImageUrl;
  final double qualityScore;
  final double yaw;
  final double pitch;
  final double blurScore;
  final String createdAt;

  FaceItem({
    required this.id,
    required this.memberId,
    required this.sampleImageUrl,
    this.qualityScore = 0.0,
    this.yaw = 0.0,
    this.pitch = 0.0,
    this.blurScore = 0.0,
    required this.createdAt,
  });

  factory FaceItem.fromJson(Map<String, dynamic> json) {
    return FaceItem(
      id: json['id']?.toString() ?? '',
      memberId: json['member_id']?.toString() ?? '',
      sampleImageUrl: json['sample_image_url'] ?? json['image_url'] ?? '',
      qualityScore: (json['quality_score'] as num?)?.toDouble() ?? 0.0,
      yaw: (json['yaw'] as num?)?.toDouble() ?? 0.0,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 0.0,
      blurScore: (json['blur_score'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class MemberItem {
  final String id;
  final String name;
  final String role; // 'family', 'guest', 'neighbor', 'staff'
  final String? avatarUrl;
  final bool isActive;
  final int faceCount;
  final List<FaceItem> faces;
  final String createdAt;

  MemberItem({
    required this.id,
    required this.name,
    this.role = 'family',
    this.avatarUrl,
    this.isActive = true,
    this.faceCount = 0,
    this.faces = const [],
    required this.createdAt,
  });

  factory MemberItem.fromJson(Map<String, dynamic> json) {
    final facesList = json['faces'] as List<dynamic>? ?? [];
    return MemberItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'family',
      avatarUrl: json['avatar_url'],
      isActive: json['is_active'] ?? true,
      faceCount: json['face_count'] ?? facesList.length,
      faces: facesList.map((e) => FaceItem.fromJson(e as Map<String, dynamic>)).toList(),
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'role': role,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
  };
}

class MemberListResponse {
  final List<MemberItem> data;
  final int total;
  final int familyCount;
  final int guestCount;

  MemberListResponse({
    required this.data,
    required this.total,
    this.familyCount = 0,
    this.guestCount = 0,
  });

  factory MemberListResponse.fromJson(dynamic json) {
    if (json is List) {
      final list = json.map((e) => MemberItem.fromJson(e as Map<String, dynamic>)).toList();
      return MemberListResponse(data: list, total: list.length);
    }
    if (json is Map<String, dynamic>) {
      final list = (json['data'] as List<dynamic>? ?? [])
          .map((e) => MemberItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return MemberListResponse(
        data: list,
        total: json['total'] ?? list.length,
        familyCount: json['family_count'] ?? 0,
        guestCount: json['guest_count'] ?? 0,
      );
    }
    return MemberListResponse(data: [], total: 0);
  }
}

