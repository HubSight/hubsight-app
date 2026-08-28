import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import '../models/device_models.dart';
import '../models/member_models.dart';
import '../models/nvr_models.dart';
import '../models/pool_models.dart';
import '../../features/camera/models/camera_models.dart';
import '../../features/notifications/models/notification_model.dart';
import '../storage/storage_service.dart';

final apiClientProvider = Provider((ref) {
  final storage = ref.watch(storageServiceProvider);
  final serverUrl = storage.getServerUrl() ?? 'http://10.0.2.2:8088';
  return ApiClient(storage: storage, serverUrl: serverUrl);
});

class ApiClient {
  late Dio _dio;
  String _serverUrl;
  final StorageService? _storage;

  ApiClient({
    StorageService? storage,
    String serverUrl = 'http://10.0.2.2:8088',
  })  : _storage = storage,
        _serverUrl = serverUrl {
    _initDio();
  }

  String get serverUrl => _serverUrl;
  String get baseUrl => '${_serverUrl.replaceAll(RegExp(r'/+$'), '')}/api';

  void _initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Accept'] = 'application/json';
        final token = _storage?.getAuthToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Log errors or trigger refresh
        return handler.next(error);
      },
    ));
  }

  void updateServerUrl(String newServerUrl) {
    _serverUrl = newServerUrl.trim().replaceAll(RegExp(r'/+$'), '');
    _dio.options.baseUrl = baseUrl;
  }

  Dio get client => _dio;

  Future<bool> testConnection([String? customUrl]) async {
    try {
      final target = customUrl != null
          ? '${customUrl.trim().replaceAll(RegExp(r'/+$'), '')}/api'
          : baseUrl;
      final testDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final response = await testDio.get('$target/cameras');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // 1. AUTHENTICATION & PROFILE APIS (/auth/*)
  // ==========================================

  Future<LoginResponse> login(String username, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    final loginRes = LoginResponse.fromJson(response.data as Map<String, dynamic>);
    if (loginRes.token.isNotEmpty) {
      await _storage?.setAuthToken(loginRes.token);
    }
    if (loginRes.user != null) {
      await _storage?.setUserProfile(loginRes.user!);
    }
    return loginRes;
  }

  Future<User?> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      final user = User.fromJson(response.data as Map<String, dynamic>);
      await _storage?.setUserProfile(user);
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    await _storage?.clearAuthToken();
    await _storage?.clearUserProfile();
  }

  Future<bool> verifyPassword(String password) async {
    try {
      final res = await _dio.post('/auth/verify-password', data: {'password': password});
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final response = await _dio.put('/auth/password', data: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
    return response.statusCode == 200;
  }

  Future<void> updatePreferences(PushPreferences prefs) async {
    await _dio.put('/auth/preferences', data: {
      'push_preferences': prefs.toJson(),
    });
  }

  Future<void> updateLocale(String locale) async {
    await _dio.put('/auth/locale', data: {'locale': locale});
    await _storage?.setLocale(locale);
  }

  Future<void> updateTimezone(String timezone) async {
    await _dio.put('/auth/timezone', data: {'timezone': timezone});
  }

  // ==========================================
  // 2. CAMERA & DEVICE APIS (/cameras/*, /devices/*)
  // ==========================================

  Future<List<CameraItem>> getCameras() async {
    final response = await _dio.get('/cameras');
    final list = response.data as List<dynamic>? ?? [];
    return list.map((item) => CameraItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<CameraItem> createCamera(Map<String, dynamic> payload) async {
    final response = await _dio.post('/cameras', data: payload);
    return CameraItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CameraItem> updateCamera(String id, Map<String, dynamic> payload) async {
    final response = await _dio.put('/cameras/$id', data: payload);
    return CameraItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<bool> deleteCamera(String id) async {
    final response = await _dio.delete('/cameras/$id');
    return response.statusCode == 200;
  }

  Future<bool> stopCamera(String id) async {
    final response = await _dio.post('/cameras/$id/stop');
    return response.statusCode == 200;
  }

  Future<bool> startCamera(String id) async {
    final response = await _dio.post('/cameras/$id/start');
    return response.statusCode == 200;
  }

  Future<DeviceScanJob> startDeviceScan({List<String>? extraCidrs}) async {
    final response = await _dio.post('/devices/scan', data: {
      if (extraCidrs != null) 'extra_cidrs': extraCidrs,
    });
    return DeviceScanJob.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DeviceScanJob> getDeviceScanStatus(String jobId) async {
    final response = await _dio.get('/devices/scan/$jobId');
    return DeviceScanJob.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<RecognitionLog>> getRecognitionLogs(String cameraId, {int limit = 50}) async {
    try {
      final response = await _dio.get(
        '/cameras/$cameraId/recognition-logs',
        queryParameters: {'limit': limit},
      );
      final list = response.data as List<dynamic>? ?? [];
      return list.map((e) => RecognitionLog.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> clearRecognitionLogs(String cameraId) async {
    try {
      final res = await _dio.delete('/cameras/$cameraId/recognition-logs');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // 3. ARCHIVE & PLAYBACK APIS (/archive/*, /live/*)
  // ==========================================

  Future<List<int>> getAvailableDays(String camId, int year, int month) async {
    try {
      final response = await _dio.get(
        '/archive/$camId/available-days',
        queryParameters: {'year': year, 'month': month},
      );
      final list = response.data as List<dynamic>? ?? [];
      return list.map((e) => int.tryParse(e.toString()) ?? 0).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Recording>> getTimelineRecordings(String camId, DateTime date) async {
    try {
      final from = DateTime.utc(date.year, date.month, date.day, 0, 0, 0).toIso8601String();
      final to = DateTime.utc(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

      final response = await _dio.get(
        '/archive/timeline',
        queryParameters: {
          'from': from,
          'to': to,
          'camera_id': camId,
        },
      );
      final list = response.data as List<dynamic>? ?? [];
      return list.map((item) => Recording.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  String getRecordingStreamUrl(String recordingId, {bool download = false}) {
    return '$baseUrl/archive/$recordingId/stream${download ? '?download=true' : ''}';
  }

  Future<Response> sendWebRtcOffer(String cameraId, String sdpOffer) async {
    return await _dio.post(
      '/live/$cameraId/webrtc',
      data: sdpOffer,
      options: Options(
        headers: {'Content-Type': 'application/sdp'},
        responseType: ResponseType.plain,
      ),
    );
  }

  Future<void> sendStreamHeartbeat(String cameraId, String poolStreamName) async {
    await _dio.post(
      '/live/$cameraId/heartbeat',
      queryParameters: {'stream_name': poolStreamName},
    );
  }

  // ==========================================
  // 4. MEMBERS & FACIAL ENROLLMENT (/members/*)
  // ==========================================

  Future<MemberListResponse> getMembers({
    String? role,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dio.get('/members', queryParameters: {
      'page': page,
      'limit': limit,
      if (role != null && role != 'all') 'role': role,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return MemberListResponse.fromJson(response.data);
  }

  Future<MemberItem> createMember(Map<String, dynamic> payload) async {
    final response = await _dio.post('/members', data: payload);
    return MemberItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MemberItem> updateMember(String id, Map<String, dynamic> payload) async {
    final response = await _dio.put('/members/$id', data: payload);
    return MemberItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<bool> deleteMember(String id) async {
    final response = await _dio.delete('/members/$id');
    return response.statusCode == 200;
  }

  Future<String> uploadMemberAvatar(String memberId, List<int> imageBytes, String filename) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(imageBytes, filename: filename),
    });
    final response = await _dio.post('/members/$memberId/avatar', data: formData);
    return response.data['avatar_url']?.toString() ?? '';
  }

  Future<bool> deleteMemberAvatar(String memberId) async {
    final response = await _dio.delete('/members/$memberId/avatar');
    return response.statusCode == 200;
  }

  Future<List<FaceItem>> getMemberFaces(String memberId) async {
    try {
      final response = await _dio.get('/members/$memberId/faces');
      final list = response.data as List<dynamic>? ?? [];
      return list.map((e) => FaceItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<FaceItem> enrollMemberFace(String memberId, List<int> imageBytes, String filename) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(imageBytes, filename: filename),
    });
    final response = await _dio.post('/members/$memberId/faces/enroll', data: formData);
    return FaceItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<bool> deleteMemberFace(String memberId, String faceId) async {
    final response = await _dio.delete('/members/$memberId/faces/$faceId');
    return response.statusCode == 200;
  }

  Future<bool> deleteAllMemberFaces(String memberId) async {
    final response = await _dio.delete('/members/$memberId/faces');
    return response.statusCode == 200;
  }

  // ==========================================
  // 5. NOTIFICATIONS & PUSH (/notifications/*)
  // ==========================================

  Future<NotificationResponse> getNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      if (response.data is Map<String, dynamic>) {
        return NotificationResponse.fromJson(response.data as Map<String, dynamic>);
      }
      return NotificationResponse(unreadCount: 0, notifications: []);
    } catch (_) {
      return NotificationResponse(unreadCount: 0, notifications: []);
    }
  }

  Future<bool> markAllNotificationsRead() async {
    try {
      await _dio.post('/notifications/read-all');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markNotificationRead(String id) async {
    try {
      await _dio.patch('/notifications/$id/read');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      await _dio.delete('/notifications/$id');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearAllNotifications() async {
    try {
      await _dio.delete('/notifications');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getPushConfig() async {
    final response = await _dio.get('/notifications/push-config');
    return response.data as Map<String, dynamic>;
  }

  Future<bool> subscribePush(Map<String, dynamic> subscriptionPayload) async {
    final response = await _dio.post('/notifications/subscribe-push', data: subscriptionPayload);
    return response.statusCode == 200;
  }

  Future<bool> sendTestNotification() async {
    try {
      final res = await _dio.post('/notifications/test');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // 6. NVR MONITOR & RECORDER (/recorder/*, /settings/*)
  // ==========================================

  Future<NvrStatusResponse> getNvrStatus() async {
    final response = await _dio.get('/recorder/status');
    return NvrStatusResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<bool> updateNvrSettings({
    String? nvrStatus,
    int? storageQuotaGb,
    int? retentionDays,
  }) async {
    final response = await _dio.put('/settings', data: {
      if (nvrStatus != null) 'nvr_status': nvrStatus,
      if (storageQuotaGb != null) 'storage_quota_gb': storageQuotaGb,
      if (retentionDays != null) 'retention_days': retentionDays,
    });
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> cleanupStorage() async {
    final response = await _dio.post('/settings/storage/cleanup');
    return response.data as Map<String, dynamic>;
  }

  // ==========================================
  // 7. CONNECTION POOL MONITOR (/pool/*)
  // ==========================================

  Future<PoolStatusSummary> getPoolStatus() async {
    final response = await _dio.get('/pool/status');
    return PoolStatusSummary.fromJson(response.data as Map<String, dynamic>);
  }
}
