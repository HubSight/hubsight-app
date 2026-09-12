import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cctv_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';
import '../../core/network/sdk_provider.dart';
import '../camera/playback_screen.dart';
import '../common/app_sidebar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  List<Camera> _cameras = [];
  bool _isLoading = true;
  String? _userToken;
  bool _isMultiViewMode = false;
  MultiViewStreamSession? _multiViewSession;

  StreamSubscription? _cameraStatusSub;
  StreamSubscription? _aiAlertSub;

  @override
  void initState() {
    super.initState();
    _loadCamerasAndToken();
    _setupRelayListeners();
  }

  Future<void> _loadCamerasAndToken() async {
    setState(() => _isLoading = true);
    final sdk = ref.read(hubsightSdkProvider);
    if (sdk == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final token = await sdk.storage.getAccessToken() ?? '';
      final cameras = await sdk.cameras.listCameras();

      if (mounted) {
        setState(() {
          _userToken = token;
          _cameras = cameras;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load cameras: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupRelayListeners() {
    final sdk = ref.read(hubsightSdkProvider);
    if (sdk == null) return;

    // Listen to camera status changes (online/offline/stopped)
    _cameraStatusSub = sdk.relay.onCameraStatus.listen((event) {
      if (!mounted) return;
      setState(() {
        _cameras = _cameras.map((c) {
          if (c.id == event.cameraId) {
            return Camera(
              id: c.id,
              name: c.name,
              host: c.host,
              isActive: event.isOnline,
              isStopped: !event.isOnline,
              enableAI: c.enableAI,
              thumbnailUrl: c.thumbnailUrl,
              streamName: c.streamName,
            );
          }
          return c;
        }).toList();
      });
    });

    // Listen to AI real-time alerts
    _aiAlertSub = sdk.relay.onAIAlert.listen((event) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Cảnh báo AI: ${event.eventType} tại camera ${event.cameraId}'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE85D10),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    });
  }

  void _toggleMultiViewMode() {
    final sdk = ref.read(hubsightSdkProvider);
    if (sdk == null) return;

    setState(() {
      _isMultiViewMode = !_isMultiViewMode;
      if (_isMultiViewMode) {
        _multiViewSession = sdk.createMultiViewSession();
      } else {
        _multiViewSession?.stopAll();
        _multiViewSession = null;
      }
    });
  }

  @override
  void dispose() {
    _cameraStatusSub?.cancel();
    _aiAlertSub?.cancel();
    _multiViewSession?.stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sdk = ref.watch(hubsightSdkProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      drawer: const AppSidebar(activeRoute: 'home'),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          l10n.dashboardTitle,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isMultiViewMode ? Icons.grid_view : Icons.view_quilt_outlined,
              color: _isMultiViewMode ? const Color(0xFFE85D10) : const Color(0xFF94A3B8),
            ),
            tooltip: l10n.multiViewTitle,
            onPressed: _cameras.isEmpty ? null : _toggleMultiViewMode,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8)),
            onPressed: _loadCamerasAndToken,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE85D10)))
          : _cameras.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_outlined, size: 48, color: Color(0xFF64748B)),
                      const SizedBox(height: 12),
                      Text(
                        l10n.dashboardNoCameras,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      ),
                    ],
                  ),
                )
              : _isMultiViewMode && _multiViewSession != null
                  ? _buildMultiViewGrid(sdk!)
                  : _buildSnapshotGrid(sdk!, l10n),
    );
  }

  Widget _buildMultiViewGrid(HubSightSDK sdk) {
    final activeCameraIds = _cameras.where((c) => c.isStreaming).map((c) => c.id).toList();

    if (activeCameraIds.isEmpty) {
      return const Center(
        child: Text(
          'Không có camera nào đang hoạt động để phát trực tiếp',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: HubSightMultiViewGrid(
        session: _multiViewSession!,
        cameraIds: activeCameraIds,
        crossAxisCount: activeCameraIds.length > 2 ? 2 : 1,
        aspectRatio: 16 / 9,
      ),
    );
  }

  Widget _buildSnapshotGrid(HubSightSDK sdk, AppLocalizations l10n) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _cameras.length,
      itemBuilder: (context, index) {
        final cam = _cameras[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlaybackScreen()),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Name and Status pill
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cam.isStreaming
                              ? const Color(0xFF10B981).withOpacity(0.15)
                              : Colors.redAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.videocam,
                          color: cam.isStreaming ? const Color(0xFF10B981) : Colors.redAccent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cam.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              cam.host,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cam.isStreaming
                              ? const Color(0xFF10B981).withOpacity(0.2)
                              : const Color(0xFFEF4444).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          cam.isStreaming ? l10n.cameraOnline : l10n.cameraStopped,
                          style: TextStyle(
                            color: cam.isStreaming ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 640p 15FPS Real-Time Snapshot Viewer
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: HubSightCameraThumbnail(
                    gatewayUrl: sdk.config.urls.gatewayUrl,
                    thumbnailUrl: cam.thumbnailUrl,
                    apiKey: sdk.config.apiKey,
                    token: _userToken ?? '',
                    isStopped: cam.isStopped,
                    refreshInterval: const Duration(seconds: 4),
                    fit: BoxFit.cover,
                    stoppedPlaceholder: Container(
                      color: const Color(0xFF0F172A),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam_off_outlined, color: Color(0xFF64748B), size: 36),
                            const SizedBox(height: 8),
                            Text(
                              l10n.cameraStoppedPlaceholder,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
