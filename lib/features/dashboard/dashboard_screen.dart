import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hubsight_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';
import '../../core/network/sdk_provider.dart';
import '../camera/ptz_bottom_sheet.dart';
import '../common/main_tab_screen.dart';
import '../../core/theme/app_theme.dart';

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
            return c.copyWith(
              isActive: event.isOnline,
              isStopped: !event.isOnline,
            );
          }
          return c;
        }).toList();
      });
    });

    // Listen to AI real-time alerts
    _aiAlertSub = sdk.relay.onAIAlert.listen((event) {
      if (!mounted) return;
      if (event.eventType != 'fall' && event.eventType != 'danger') return;
      final l10n = mounted ? AppLocalizations.of(context) : null;
      final alertText = l10n?.aiAlertNotification(event.eventType, event.cameraId) ??
          'Cảnh báo AI: ${event.eventType} tại camera ${event.cameraId}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(alertText),
              ),
            ],
          ),
          backgroundColor: HubSightColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: HubSightRadius.roundedXl),
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
      backgroundColor: context.bgAdaptive,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: HubSightGradients.accentHeaderAdaptive(context),
            boxShadow: [
              BoxShadow(
                color: HubSightColors.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Text(
          l10n.tabDashboard,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.4,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: _isMultiViewMode
                  ? BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Icon(
                _isMultiViewMode ? Icons.grid_view : Icons.view_quilt_outlined,
                color: Colors.white,
              ),
            ),
            tooltip: l10n.multiViewTitle,
            onPressed: _cameras.isEmpty ? null : () {
              HapticFeedback.lightImpact();
              _toggleMultiViewMode();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadCamerasAndToken();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: HubSightColors.primary))
          : _cameras.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_off_outlined, size: 48, color: context.textMutedAdaptive),
                      const SizedBox(height: 12),
                      Text(
                        l10n.dashboardNoCameras,
                        style: TextStyle(color: context.textSecondaryAdaptive, fontSize: 14),
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
    final l10n = AppLocalizations.of(context)!;
    final activeCameraIds = _cameras.where((c) => c.isStreaming).map((c) => c.id).toList();

    if (activeCameraIds.isEmpty) {
      return Center(
        child: Text(
          l10n.noActiveStreamingCameras,
          style: TextStyle(color: context.textMutedAdaptive),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
      child: HubSightMultiViewGrid(
        session: _multiViewSession!,
        cameraIds: activeCameraIds,
        crossAxisCount: activeCameraIds.length > 2 ? 2 : 1,
        aspectRatio: 16 / 9,
      ),
    );
  }

  Widget _buildSnapshotGrid(HubSightSDK sdk, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: _cameras.length,
      separatorBuilder: (_, __) => Divider(height: 24, thickness: 1, color: context.borderAdaptive),
      itemBuilder: (context, index) {
        final cam = _cameras[index];
        return InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(mainTabIndexProvider.notifier).state = 0;
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Name and Status pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: cam.isStreaming
                            ? const Color(0x2610B981)
                            : HubSightColors.errorBg,
                        borderRadius: HubSightRadius.roundedXl,
                        border: Border.all(
                          color: cam.isStreaming
                              ? const Color(0x4D10B981)
                              : HubSightColors.errorBorder,
                        ),
                      ),
                      child: Icon(
                        Icons.videocam,
                        color: cam.isStreaming ? const Color(0xFF10B981) : HubSightColors.error,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                cam.name,
                                style: TextStyle(
                                  color: context.textPrimaryAdaptive,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (cam.onvifPtzSupported) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                                  ),
                                  child: const Text('PTZ', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                                ),
                              ],
                              if (cam.onvifEnabled) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                  ),
                                  child: const Text('ONVIF', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            cam.host,
                            style: TextStyle(
                              color: context.textMutedAdaptive,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (cam.onvifPtzSupported) ...[
                      InkWell(
                        key: Key('dashboard-ptz-${cam.id}'),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          PtzBottomSheet.show(context, camera: cam);
                        },
                        borderRadius: HubSightRadius.roundedXl,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                            borderRadius: HubSightRadius.roundedXl,
                            border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.control_camera_rounded, size: 13, color: Color(0xFF3B82F6)),
                              SizedBox(width: 4),
                              Text(
                                'PTZ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cam.isStreaming
                            ? const Color(0x2610B981)
                            : HubSightColors.errorBg,
                        borderRadius: HubSightRadius.roundedXl,
                        border: Border.all(
                          color: cam.isStreaming
                              ? const Color(0x4D10B981)
                              : HubSightColors.errorBorder,
                        ),
                      ),
                      child: Text(
                        cam.isStreaming ? l10n.cameraOnline : l10n.cameraStopped,
                        style: TextStyle(
                          color: cam.isStreaming ? const Color(0xFF34D399) : HubSightColors.errorText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 16:9 Real-Time Snapshot Viewer
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: HubSightCameraThumbnail(
                    gatewayUrl: sdk.config.urls.gatewayUrl,
                    thumbnailUrl: cam.thumbnailUrl,
                    apiKey: sdk.config.apiKey,
                    token: _userToken ?? '',
                    isStopped: cam.isStopped,
                    refreshInterval: const Duration(seconds: 4),
                    fit: BoxFit.cover,
                    stoppedPlaceholder: Container(
                      color: context.bgAdaptive,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam_off_outlined, color: context.textMutedAdaptive, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              l10n.cameraStoppedPlaceholder,
                              style: TextStyle(color: context.textMutedAdaptive, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
