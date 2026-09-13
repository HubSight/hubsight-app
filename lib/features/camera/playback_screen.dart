import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hubsight_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';
import '../../core/network/sdk_provider.dart';
import 'models/recognition_log.dart';
import 'webrtc_viewer.dart';
import 'ptz_bottom_sheet.dart';
import 'onvif_discovery_sheet.dart';
import '../common/main_tab_screen.dart';
import '../../core/theme/app_theme.dart';

class PlaybackScreen extends ConsumerStatefulWidget {
  const PlaybackScreen({super.key});

  @override
  ConsumerState<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends ConsumerState<PlaybackScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Camera> _cameras = [];
  Camera? _selectedCam;
  DateTime _selectedDate = DateTime.now();
  List<int> _availableDays = [];
  List<ArchiveSegment> _recordings = [];
  ArchiveSegment? _activeRecording;
  final ScrollController _cameraScrollController = ScrollController();

  bool _isLoadingCameras = true;
  bool _isLoadingTimeline = false;
  bool _isPlayingArchive = true;
  double _archiveCurrentSeconds = 0.0;
  double _archiveDurationSeconds = 30.0;
  double _playbackSpeed = 1.0;
  bool _isFullscreen = false;
  Orientation? _lastOrientation;
  final GlobalKey _liveViewerKey = GlobalKey();

  Future<void> _toggleFullscreen() async {
    final next = !_isFullscreen;
    setState(() => _isFullscreen = next);
    ref.read(isFullScreenPlayerProvider.notifier).state = next;

    if (next) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      // Re-enable device orientation sensors after returning to portrait
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && !_isFullscreen) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        }
      });
    }
  }

  void _openPtzController() {
    if (_selectedCam == null) return;
    HapticFeedback.lightImpact();
    PtzBottomSheet.show(context, camera: _selectedCam!);
  }

  // Mode: 'live' | 'archive'
  String _mode = 'live';
  String _filterPeriod = 'all'; // 'all', 'morning', 'afternoon', 'evening'
  int _streamReloadIndex = 0;

  List<RecognitionLog> _recognitionLogs = [];
  bool _isLoadingLogs = false;

  StreamSubscription? _notificationSub;
  StreamSubscription? _cameraEventSub;
  Timer? _archiveTimer;
  DateTime? _lastAlertSnackBarTime;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initData();
  }

  Future<void> _initData() async {
    await _fetchCameras();

    final sdk = ref.read(hubsightSdkProvider);
    if (sdk != null) {
      sdk.relay.connect();

      _notificationSub = sdk.relay.onAIAlert.listen((event) {
        if (!mounted) return;
        // Don't flood SnackBars on continuous AI detection / bbox packets
        if (event.eventType != 'fall' && event.eventType != 'danger') return;

        final now = DateTime.now();
        if (_lastAlertSnackBarTime != null &&
            now.difference(_lastAlertSnackBarTime!).inSeconds < 10) {
          return;
        }
        _lastAlertSnackBarTime = now;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Cảnh báo AI: ${event.title.isNotEmpty ? event.title : event.eventType} tại camera ${event.cameraId}'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: HubSightRadius.roundedXl),
          ),
        );
      });

      _cameraEventSub = sdk.relay.onCameraStatus.listen((event) {
        if (!mounted) return;
        final camId = event.cameraId;
        final isStopped = !event.isOnline;

        setState(() {
          _cameras = _cameras.map((c) {
            if (c.id == camId) {
              return c.copyWith(
                isActive: event.isOnline,
                isStopped: isStopped,
              );
            }
            return c;
          }).toList();

          if (_selectedCam?.id == camId) {
            _selectedCam = _selectedCam!.copyWith(
              isActive: event.isOnline,
              isStopped: isStopped,
            );
          }
        });
      });
    }
  }

  Future<void> _fetchCameras() async {
    setState(() => _isLoadingCameras = true);
    try {
      final sdk = ref.read(hubsightSdkProvider);
      if (sdk != null) {
        final cameras = await sdk.cameras.listCameras();
        if (mounted) {
          setState(() {
            _cameras = cameras;

            if (_cameras.isNotEmpty && _selectedCam == null) {
              _selectedCam = _cameras.firstWhere((c) => !c.isStopped, orElse: () => _cameras.first);
            }
            _isLoadingCameras = false;
          });

          if (_selectedCam != null) {
            _fetchAvailableDays();
            _fetchTimeline();
            _fetchRecognitionLogs();
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching cameras: $e');
      if (mounted) setState(() => _isLoadingCameras = false);
    }
  }

  Future<void> _fetchAvailableDays() async {
    if (_selectedCam == null) return;
    try {
      final sdk = ref.read(hubsightSdkProvider);
      if (sdk != null) {
        final calendar = await sdk.archive.getCalendar(
          cameraId: _selectedCam!.id,
          year: _selectedDate.year,
          month: _selectedDate.month,
        );
        if (mounted) {
          setState(() {
            _availableDays = calendar.availableDays
                .map((d) => DateTime.tryParse(d)?.day ?? int.tryParse(d) ?? 0)
                .where((day) => day > 0)
                .toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchTimeline() async {
    if (_selectedCam == null) return;
    setState(() => _isLoadingTimeline = true);

    try {
      final sdk = ref.read(hubsightSdkProvider);
      if (sdk != null) {
        final from = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
        final to = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

        final segments = await sdk.archive.getTimeline(
          cameraId: _selectedCam!.id,
          from: from,
          to: to,
        );

        if (mounted) {
          setState(() {
            _recordings = segments;

            _isLoadingTimeline = false;
            if (_recordings.isNotEmpty) {
              _activeRecording ??= _recordings.first;
              _archiveDurationSeconds = (_activeRecording!.durationSeconds > 0
                      ? _activeRecording!.durationSeconds
                      : 30)
                  .toDouble();
            } else {
              _activeRecording = null;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching timeline: $e');
      if (mounted) setState(() => _isLoadingTimeline = false);
    }
  }

  Future<void> _fetchRecognitionLogs() async {
    if (_selectedCam == null) return;
    setState(() => _isLoadingLogs = true);
    try {
      final sdk = ref.read(hubsightSdkProvider);
      if (sdk != null) {
        final res = await sdk.client.get('/cameras/${_selectedCam!.id}/recognition-logs');
        List rawList = [];
        if (res is List) {
          rawList = res;
        } else if (res is Map && res['data'] is List) {
          rawList = res['data'] as List;
        } else if (res is Map && res['logs'] is List) {
          rawList = res['logs'] as List;
        }
        if (mounted) {
          setState(() {
            _recognitionLogs = rawList
                .map((e) => RecognitionLog.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
          });
        }
      }
    } catch (_) {
      // Ignored
    } finally {
      if (mounted) setState(() => _isLoadingLogs = false);
    }
  }

  void _onSelectCamera(Camera cam) {
    setState(() {
      _selectedCam = cam;
      _mode = 'live';
      _activeRecording = null;
      _recordings = [];
    });
    _fetchAvailableDays();
    _fetchTimeline();
    _fetchRecognitionLogs();
  }

  void _onSelectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _mode = 'archive';
    });
    _fetchTimeline();
  }

  void _onSelectRecording(ArchiveSegment rec, [double startOffsetSeconds = 0.0]) {
    setState(() {
      _mode = 'archive';
      _activeRecording = rec;
      _archiveCurrentSeconds = startOffsetSeconds;
      _archiveDurationSeconds = (rec.durationSeconds > 0 ? rec.durationSeconds : 30).toDouble();
      _isPlayingArchive = true;
    });
    _startArchiveTimer();
  }

  void _startArchiveTimer() {
    _archiveTimer?.cancel();
    _archiveTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isPlayingArchive || !mounted) return;
      setState(() {
        _archiveCurrentSeconds += 0.5 * _playbackSpeed;
        if (_archiveCurrentSeconds >= _archiveDurationSeconds) {
          _archiveCurrentSeconds = _archiveDurationSeconds;
          _isPlayingArchive = false;
        }
      });
    });
  }

  void _toggleArchivePlay() {
    setState(() {
      _isPlayingArchive = !_isPlayingArchive;
      if (_isPlayingArchive && _archiveCurrentSeconds >= _archiveDurationSeconds) {
        _archiveCurrentSeconds = 0.0;
      }
    });
    if (_isPlayingArchive) {
      _startArchiveTimer();
    } else {
      _archiveTimer?.cancel();
    }
  }

  void _handleGoLive() {
    setState(() {
      _mode = 'live';
      _isPlayingArchive = false;
    });
    _archiveTimer?.cancel();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _cameraScrollController.dispose();
    _notificationSub?.cancel();
    _cameraEventSub?.cancel();
    _archiveTimer?.cancel();
    super.dispose();
  }

  List<ArchiveSegment> get _filteredRecordings {
    if (_filterPeriod == 'all') return _recordings;
    return _recordings.where((rec) {
      final hour = rec.startAt.hour;
      if (_filterPeriod == 'morning') return hour >= 0 && hour < 12;
      if (_filterPeriod == 'afternoon') return hour >= 12 && hour < 18;
      if (_filterPeriod == 'evening') return hour >= 18 && hour < 24;
      return true;
    }).toList();
  }

  String _formatSeconds(double sec) {
    final s = sec.toInt();
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCamStopped = _selectedCam?.isStopped ?? false;
    final dateFormatted = DateFormat('dd/MM/yyyy').format(_selectedDate);

    final orientation = MediaQuery.of(context).orientation;
    if (_lastOrientation != orientation) {
      final prev = _lastOrientation;
      _lastOrientation = orientation;
      if (prev != null) {
        if (orientation == Orientation.landscape && !_isFullscreen) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isFullscreen) {
              setState(() => _isFullscreen = true);
              ref.read(isFullScreenPlayerProvider.notifier).state = true;
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
            }
          });
        } else if (orientation == Orientation.portrait && _isFullscreen) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isFullscreen) {
              setState(() => _isFullscreen = false);
              ref.read(isFullScreenPlayerProvider.notifier).state = false;
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            }
          });
        }
      }
    }

    if (_isFullscreen) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _toggleFullscreen();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            top: false,
            bottom: false,
            left: true,
            right: true,
            child: SizedBox.expand(
              child: _buildVideoPlayerSection(isCamStopped, l10n, isFullscreen: true),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
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
        title: const Text(
          'HubSight',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.4,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
            tooltip: l10n.loading,
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _streamReloadIndex++;
              });
              _fetchCameras();
              _fetchAvailableDays();
              _fetchTimeline();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _streamReloadIndex++;
          });
          await _fetchCameras();
          await _fetchAvailableDays();
          await _fetchTimeline();
        },
        color: HubSightColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Video Player Area (16:9 Widescreen)
              _buildVideoPlayerSection(isCamStopped, l10n),

              // 2. Horizontal Quick Camera Selector Bar
              _buildCameraQuickBar(l10n),

              // 3. Unified Timeline & Playback Section
              _buildUnifiedTimelineSection(dateFormatted, l10n),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Divider(height: 20, thickness: 1, color: context.borderAdaptive),
              ),

              // 4. Live Activity & Recognition Section
              _buildActivitySection(l10n),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. Video Player Section (16:9 Widescreen) ---
  Widget _buildVideoPlayerSection(bool isStopped, AppLocalizations l10n, {bool isFullscreen = false}) {
    final playerWidget = Container(
      color: Colors.black,
      child: isStopped && _mode == 'live'
          ? _buildStoppedCameraState(l10n)
          : _mode == 'live'
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    WebRTCViewer(
                      key: _liveViewerKey,
                      cameraId: _selectedCam?.id ?? '',
                      cameraName: _selectedCam?.name,
                      enableAi: _selectedCam?.enableAI ?? true,
                      showBbox: true,
                      isFullscreen: isFullscreen,
                      onToggleFullscreen: _toggleFullscreen,
                      streamReloadIndex: _streamReloadIndex,
                      hasPtz: _selectedCam?.onvifPtzSupported ?? false,
                      onOpenPtz: _openPtzController,
                    ),
                    // Top Video Info Bar (portrait only)
                    if (!isFullscreen)
                      Positioned(
                        top: 10,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _selectedCam?.name ?? 'LIVE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              if (_selectedCam?.onvifPtzSupported == true) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.5)),
                                  ),
                                  child: const Text(
                                    'PTZ',
                                    style: TextStyle(
                                      color: Color(0xFF93C5FD),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    // Top-right PTZ Controller Shortcut Button (portrait only)
                    if (!isFullscreen && _selectedCam?.onvifPtzSupported == true)
                      Positioned(
                        top: 10,
                        right: 12,
                        child: InkWell(
                          key: const Key('playback-ptz-action-button'),
                          onTap: _openPtzController,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.control_camera_rounded, color: Color(0xFF60A5FA), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'PTZ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : _buildArchiveVideoPlayer(l10n, isFullscreen: isFullscreen),
    );

    if (isFullscreen) {
      return playerWidget;
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: playerWidget,
    );
  }

  // --- Archive Video Player with YouTube-style Controls ---
  Widget _buildArchiveVideoPlayer(AppLocalizations l10n, {bool isFullscreen = false}) {
    final progress = _archiveDurationSeconds > 0
        ? (_archiveCurrentSeconds / _archiveDurationSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Simulated video frame / poster
        Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam_rounded, size: 54, color: HubSightColors.primary),
                const SizedBox(height: 8),
                Text(
                  _activeRecording != null
                      ? DateFormat('yyyy-MM-dd HH:mm:ss').format(_activeRecording!.startAt)
                      : l10n.playingArchive,
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ),

        // Top Gradient & "Switch to Live" Button
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Start - End Segment Time & Fullscreen Back Button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFullscreen) ...[
                      InkWell(
                        key: const Key('archive-fullscreen-back-button'),
                        onTap: _toggleFullscreen,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: HubSightRadius.roundedXl,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        _activeRecording != null
                            ? DateFormat('HH:mm:ss').format(_activeRecording!.startAt)
                            : '00:00:00',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // Switch to Live Button
                ElevatedButton.icon(
                  onPressed: _handleGoLive,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HubSightColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: HubSightRadius.roundedXl),
                  ),
                  icon: const Icon(Icons.radio_button_checked, size: 13),
                  label: const Text('Trực tiếp', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),

        // Bottom Controls Bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress Scrub Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: HubSightColors.primary,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: HubSightColors.primary,
                  ),
                  child: Slider(
                    value: progress,
                    onChanged: (val) {
                      setState(() {
                        _archiveCurrentSeconds = val * _archiveDurationSeconds;
                      });
                    },
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Play / Pause & Skip
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isPlayingArchive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: _toggleArchivePlay,
                        ),
                        IconButton(
                          icon: const Icon(Icons.replay_10_rounded, color: Colors.white70, size: 20),
                          onPressed: () {
                            setState(() {
                              _archiveCurrentSeconds = (_archiveCurrentSeconds - 10).clamp(0.0, _archiveDurationSeconds);
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.forward_10_rounded, color: Colors.white70, size: 20),
                          onPressed: () {
                            setState(() {
                              _archiveCurrentSeconds = (_archiveCurrentSeconds + 10).clamp(0.0, _archiveDurationSeconds);
                            });
                          },
                        ),
                        Text(
                          '${_formatSeconds(_archiveCurrentSeconds)} / ${_formatSeconds(_archiveDurationSeconds)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),

                    // Speed Selector & Fullscreen Toggle
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<double>(
                          initialValue: _playbackSpeed,
                          color: context.cardAdaptive,
                          onSelected: (rate) {
                            setState(() => _playbackSpeed = rate);
                          },
                          itemBuilder: (context) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((rate) {
                            return PopupMenuItem<double>(
                              value: rate,
                              child: Text('${rate}x', style: TextStyle(
                                fontWeight: _playbackSpeed == rate ? FontWeight.bold : FontWeight.normal,
                                color: _playbackSpeed == rate ? HubSightColors.primary : context.textPrimaryAdaptive,
                              )),
                            );
                          }).toList(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: HubSightRadius.roundedXl,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              '${_playbackSpeed}x',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          key: const Key('archive-fullscreen-button'),
                          onTap: _toggleFullscreen,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: HubSightRadius.roundedXl,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Icon(
                              isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoppedCameraState(AppLocalizations l10n) {
    final camName = _selectedCam?.name ?? 'Facetime HD Cam';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.surfaceAdaptive,
                borderRadius: HubSightRadius.roundedCard,
                border: Border.all(color: context.borderAdaptive),
              ),
              child: Icon(
                Icons.videocam_off_outlined,
                color: context.textSecondaryAdaptive,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.cameraStoppedStatus,
              style: TextStyle(
                color: context.textMutedAdaptive,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.cameraStoppedTitle(camName),
              style: TextStyle(
                color: context.textPrimaryAdaptive,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.cameraStoppedDesc,
              style: TextStyle(
                color: context.textSecondaryAdaptive,
                fontSize: 11.5,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. Camera Quick Selector Bar ---
  Widget _buildCameraQuickBar(AppLocalizations l10n) {
    if (_isLoadingCameras && _cameras.isEmpty) {
      return const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: HubSightColors.primary),
          ),
        ),
      );
    }

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        controller: _cameraScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _cameras.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == _cameras.length) {
            // More / List picker button
            return InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _showCameraPicker(l10n);
              },
              borderRadius: HubSightRadius.roundedFull,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.surfaceAdaptive,
                  borderRadius: HubSightRadius.roundedFull,
                  border: Border.all(color: context.borderAdaptive),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 14, color: context.textSecondaryAdaptive),
                    const SizedBox(width: 4),
                    Text(
                      'Tất cả',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondaryAdaptive,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final cam = _cameras[index];
          final isSelected = cam.id == _selectedCam?.id;
          final isStopped = cam.isStopped;

          return InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              _onSelectCamera(cam);
            },
            borderRadius: HubSightRadius.roundedFull,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? HubSightColors.primary.withValues(alpha: 0.16)
                    : context.surfaceAdaptive,
                borderRadius: HubSightRadius.roundedFull,
                border: Border.all(
                  color: isSelected ? HubSightColors.primary : context.borderAdaptive,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isStopped
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cam.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? HubSightColors.primary
                          : context.textPrimaryAdaptive,
                    ),
                  ),
                  if (cam.onvifPtzSupported) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.control_camera_rounded,
                      size: 12,
                      color: isSelected ? HubSightColors.primary : const Color(0xFF60A5FA),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCameraPicker(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardAdaptive,
      shape: RoundedRectangleBorder(
        borderRadius: HubSightRadius.roundedSheet,
        side: BorderSide(color: context.borderAdaptive),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n.selectCamera,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.textPrimaryAdaptive),
                ),
              ),
              Divider(height: 1, color: context.borderAdaptive),
              Flexible(
                child: _isLoadingCameras
                    ? const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: HubSightColors.primary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _cameras.length,
                        itemBuilder: (context, index) {
                          final cam = _cameras[index];
                          final isSelected = cam.id == _selectedCam?.id;
                          return ListTile(
                            leading: Icon(
                              cam.isStopped
                                  ? Icons.videocam_off_outlined
                                  : Icons.videocam_outlined,
                              color: isSelected
                                  ? HubSightColors.primary
                                  : context.textMutedAdaptive,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cam.name,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? HubSightColors.primary : context.textPrimaryAdaptive,
                                    ),
                                  ),
                                ),
                                if (cam.onvifPtzSupported)
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                                    ),
                                    child: const Text(
                                      'PTZ',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                                    ),
                                  ),
                                if (cam.onvifEnabled)
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                    ),
                                    child: const Text(
                                      'ONVIF',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check,
                                    color: HubSightColors.primary)
                                : null,
                            onTap: () {
                              Navigator.pop(context);
                              _onSelectCamera(cam);
                            },
                          );
                        },
                      ),
              ),
              Divider(height: 1, color: context.borderAdaptive),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.radar_rounded, color: Color(0xFF10B981), size: 18),
                ),
                title: Text(
                  l10n.onvifDiscovery,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryAdaptive,
                  ),
                ),
                subtitle: Text(
                  l10n.onvifDiscoverySubtitle,
                  style: TextStyle(fontSize: 11, color: context.textMutedAdaptive),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () {
                  Navigator.pop(context);
                  OnvifDiscoverySheet.show(
                    context,
                    existingCameras: _cameras,
                    initialCamera: _selectedCam,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      selectableDayPredicate: (date) {
        if (_availableDays.isEmpty) return true;
        return _availableDays.contains(date.day);
      },
      builder: (context, child) {
        final isDark = context.isDarkMode;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: HubSightColors.primary,
                    surface: context.cardAdaptive,
                    onSurface: context.textPrimaryAdaptive,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: ColorScheme.light(
                    primary: HubSightColors.primary,
                    surface: context.cardAdaptive,
                    onSurface: context.textPrimaryAdaptive,
                  ),
                ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _onSelectDate(picked);
    }
  }

  // --- 3. Unified Timeline & Playback Section ---
  Widget _buildUnifiedTimelineSection(String dateFormatted, AppLocalizations l10n) {
    final count = _recordings.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Row 1: Date Selector + Live Switch Button + Record count badge
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Date Selector Button
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showDatePicker();
                },
                borderRadius: HubSightRadius.roundedXl,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.surfaceAdaptive,
                    borderRadius: HubSightRadius.roundedXl,
                    border: Border.all(color: context.borderAdaptive),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 13, color: HubSightColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        dateFormatted,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryAdaptive,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 15, color: context.textSecondaryAdaptive),
                    ],
                  ),
                ),
              ),

              // Live / Records indicator
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Live Button
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _handleGoLive();
                    },
                    borderRadius: HubSightRadius.roundedXl,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _mode == 'live' ? HubSightColors.primary : context.surfaceAdaptive,
                        borderRadius: HubSightRadius.roundedXl,
                        border: Border.all(
                          color: _mode == 'live' ? HubSightColors.primary : context.borderAdaptive,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.radio_button_checked,
                            size: 11,
                            color: _mode == 'live' ? Colors.white : context.textMutedAdaptive,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Live',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _mode == 'live' ? Colors.white : context.textMutedAdaptive,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.surfaceAdaptive,
                      borderRadius: HubSightRadius.roundedXl,
                      border: Border.all(color: context.borderAdaptive),
                    ),
                    child: Text(
                      _isLoadingTimeline
                          ? l10n.loading
                          : (_recordings.isEmpty
                              ? l10n.noData
                              : l10n.recordsCount(count)),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: count > 0 ? const Color(0xFF10B981) : context.textMutedAdaptive,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Row 2: Filter period tabs (All / Morning / Afternoon / Evening)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: context.surfaceAdaptive,
              borderRadius: HubSightRadius.roundedXl,
              border: Border.all(color: context.borderAdaptive),
            ),
            child: Row(
              children: [
                Expanded(child: _buildFilterTab('all', l10n.filterAll(count))),
                Expanded(child: _buildFilterTab('morning', l10n.filterMorning)),
                Expanded(child: _buildFilterTab('afternoon', l10n.filterAfternoon)),
                Expanded(child: _buildFilterTab('evening', l10n.filterEvening)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Row 3: 24h Timeline Ruler & Track (Edge-to-Edge Full Bleed)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('00:00', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: context.textMutedAdaptive)),
              Text('06:00', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: context.textMutedAdaptive)),
              Text('12:00', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: context.textMutedAdaptive)),
              Text('18:00', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: context.textMutedAdaptive)),
              Text('24:00', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: context.textMutedAdaptive)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            return Container(
              height: 36,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.surfaceAdaptive,
                border: Border(
                  top: BorderSide(color: context.borderAdaptive),
                  bottom: BorderSide(color: context.borderAdaptive),
                ),
              ),
              child: Stack(
                children: [
                  // Subtle hour graduation ticks
                  for (int i = 1; i < 24; i++)
                    Positioned(
                      left: (i / 24.0) * barWidth,
                      top: i % 6 == 0 ? 0 : 10,
                      bottom: i % 6 == 0 ? 0 : 10,
                      child: Container(
                        width: 1,
                        color: i % 6 == 0
                            ? context.borderAdaptive
                            : context.borderAdaptive.withValues(alpha: 0.4),
                      ),
                    ),
                  // Event markers
                  for (final rec in _filteredRecordings)
                    _buildTimelineMarker(rec, barWidth),
                ],
              ),
            );
          },
        ),

        // Row 4: Event clips / Loading / Empty
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _isLoadingTimeline
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: HubSightColors.primary),
                    ),
                  ),
                )
              : _filteredRecordings.isEmpty
                  ? Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: context.surfaceAdaptive,
                        borderRadius: HubSightRadius.roundedXl,
                        border: Border.all(color: context.borderAdaptive),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_note_outlined, size: 16, color: context.textMutedAdaptive),
                          const SizedBox(width: 8),
                          Text(
                            l10n.noEventsToday,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textMutedAdaptive,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredRecordings.length.clamp(0, 8),
                          itemBuilder: (context, index) {
                            final rec = _filteredRecordings[index];
                            final isSelected = _activeRecording?.id == rec.id;
                            final duration = rec.durationSeconds > 0 ? rec.durationSeconds : 30;

                            return InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _onSelectRecording(rec);
                              },
                              borderRadius: HubSightRadius.roundedXl,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? context.surfaceElevatedAdaptive : context.surfaceAdaptive,
                                  borderRadius: HubSightRadius.roundedXl,
                                  border: Border.all(
                                    color: isSelected ? HubSightColors.primary : context.borderAdaptive,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: context.cardAdaptive,
                                        borderRadius: HubSightRadius.roundedXl,
                                      ),
                                      child: Icon(
                                        isSelected ? Icons.play_arrow_rounded : Icons.videocam_outlined,
                                        color: HubSightColors.primary,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l10n.recordingEvent(rec.eventType.toUpperCase()),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              color: isSelected ? HubSightColors.primary : context.textPrimaryAdaptive,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${DateFormat('yyyy-MM-dd HH:mm:ss').format(rec.startAt)} (${duration}s)',
                                            style: TextStyle(fontSize: 10.5, color: context.textMutedAdaptive),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.graphic_eq_rounded, color: HubSightColors.primary, size: 18),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildTimelineMarker(ArchiveSegment rec, double barWidth) {
    final start = rec.startAt;
    final totalSeconds = start.hour * 3600 + start.minute * 60 + start.second;
    final leftRatio = (totalSeconds / 86400.0).clamp(0.0, 1.0);
    final isSelected = _activeRecording?.id == rec.id;

    Color markerColor;
    switch (rec.eventType) {
      case 'danger':
        markerColor = const Color(0xFFF43F5E);
        break;
      case 'fall':
        markerColor = const Color(0xFFF59E0B);
        break;
      case 'stranger':
        markerColor = const Color(0xFFFB923C);
        break;
      default:
        markerColor = const Color(0xFF10B981);
    }

    final leftPos = (leftRatio * (barWidth - 6)).clamp(0.0, barWidth - 6);

    return Positioned(
      left: leftPos,
      top: 4,
      bottom: 4,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _onSelectRecording(rec);
        },
        child: Container(
          width: 5,
          decoration: BoxDecoration(
            color: isSelected ? HubSightColors.primary : markerColor,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
      ),
    );
  }

  // --- 4. Live Activity & Recognition Section ---
  Widget _buildActivitySection(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.face_retouching_natural_rounded, color: HubSightColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Nhật ký nhận diện gần đây',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: context.textPrimaryAdaptive),
                  ),
                ],
              ),
              Text(
                '${_recognitionLogs.length} sự kiện',
                style: TextStyle(fontSize: 11, color: context.textMutedAdaptive),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoadingLogs)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: HubSightColors.primary),
                ),
              ),
            )
          else if (_recognitionLogs.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: context.surfaceAdaptive,
                borderRadius: HubSightRadius.roundedXl,
                border: Border.all(color: context.borderAdaptive),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.face_outlined, size: 16, color: context.textMutedAdaptive),
                  const SizedBox(width: 8),
                  Text(
                    'Chưa có dữ liệu nhận diện khuôn mặt',
                    style: TextStyle(color: context.textMutedAdaptive, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recognitionLogs.length.clamp(0, 4),
              itemBuilder: (context, index) {
                final log = _recognitionLogs[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: context.surfaceAdaptive,
                    backgroundImage: log.thumbnailUrl != null ? NetworkImage(log.thumbnailUrl!) : null,
                    child: log.thumbnailUrl == null ? Icon(Icons.person, color: context.textSecondaryAdaptive, size: 16) : null,
                  ),
                  title: Text(log.memberName ?? 'Người lạ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimaryAdaptive)),
                  subtitle: Text(log.createdAt, style: TextStyle(fontSize: 10.5, color: context.textMutedAdaptive)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x2610B981),
                      borderRadius: HubSightRadius.roundedXl,
                      border: Border.all(color: const Color(0x4D10B981)),
                    ),
                    child: Text(
                      '${(log.confidence * 100).toInt()}%',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String key, String label) {
    final isSelected = _filterPeriod == key;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filterPeriod = key);
      },
      borderRadius: HubSightRadius.roundedXl,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (context.isDarkMode ? context.surfaceElevatedAdaptive : Colors.white)
              : Colors.transparent,
          borderRadius: HubSightRadius.roundedXl,
          border: isSelected ? Border.all(color: context.borderAdaptive) : null,
          boxShadow: isSelected && !context.isDarkMode
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? HubSightColors.primary : context.textMutedAdaptive,
          ),
        ),
      ),
    );
  }
}

extension ArchiveSegmentEventExt on ArchiveSegment {
  String get eventType {
    final lower = (thumbnailUrl ?? '').toLowerCase();
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
