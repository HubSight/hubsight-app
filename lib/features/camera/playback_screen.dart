import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cctv_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/device_models.dart';
import '../../core/network/sdk_provider.dart';
import 'models/camera_models.dart';
import 'webrtc_viewer.dart';
import '../notifications/notification_screen.dart';
import '../common/app_sidebar.dart';
import '../../core/theme/app_theme.dart';

class PlaybackScreen extends ConsumerStatefulWidget {
  const PlaybackScreen({super.key});

  @override
  ConsumerState<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends ConsumerState<PlaybackScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<CameraItem> _cameras = [];
  CameraItem? _selectedCam;
  DateTime _selectedDate = DateTime.now();
  List<int> _availableDays = [];
  List<Recording> _recordings = [];
  Recording? _activeRecording;

  bool _isLoadingCameras = true;
  bool _isLoadingTimeline = false;
  bool _isPlayingArchive = true;
  double _archiveCurrentSeconds = 0.0;
  double _archiveDurationSeconds = 30.0;
  double _playbackSpeed = 1.0;

  // Mode: 'live' | 'archive'
  String _mode = 'live';
  String _filterPeriod = 'all'; // 'all', 'morning', 'afternoon', 'evening'

  List<RecognitionLog> _recognitionLogs = [];
  bool _isLoadingLogs = false;

  StreamSubscription? _notificationSub;
  StreamSubscription? _cameraEventSub;
  Timer? _archiveTimer;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _fetchCameras();

    final sdk = ref.read(hubsightSdkProvider);
    if (sdk != null) {
      sdk.relay.connect();

      _notificationSub = sdk.relay.onAIAlert.listen((event) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Cảnh báo AI: ${event.eventType} tại camera ${event.cameraId}')),
              ],
            ),
            backgroundColor: HubSightColors.primary,
            behavior: SnackBarBehavior.floating,
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
              return CameraItem(
                id: c.id,
                name: c.name,
                host: c.host,
                brand: c.brand,
                isActive: event.isOnline,
                isStopped: isStopped,
                enableAi: c.enableAi,
                showBbox: c.showBbox,
              );
            }
            return c;
          }).toList();

          if (_selectedCam?.id == camId) {
            _selectedCam = CameraItem(
              id: _selectedCam!.id,
              name: _selectedCam!.name,
              host: _selectedCam!.host,
              brand: _selectedCam!.brand,
              isActive: event.isOnline,
              isStopped: isStopped,
              enableAi: _selectedCam!.enableAi,
              showBbox: _selectedCam!.showBbox,
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
            _cameras = cameras.map((c) => CameraItem(
              id: c.id,
              name: c.name,
              host: c.host,
              isActive: c.isActive,
              isStopped: c.isStopped,
              enableAi: c.enableAI,
            )).toList();

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
            _recordings = segments.map((s) => Recording(
              id: s.id,
              cameraId: s.cameraId,
              startAt: s.startAt.toIso8601String(),
              endAt: s.endAt.toIso8601String(),
              durationSeconds: s.durationSeconds,
              filePath: 'recording_${s.id}.mp4',
              thumbnailPath: s.thumbnailUrl,
              sizeBytes: s.sizeBytes,
              createdAt: s.startAt.toIso8601String(),
            )).toList();

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
        if (mounted && res is List) {
          setState(() {
            _recognitionLogs = res.map((e) => RecognitionLog.fromJson(Map<String, dynamic>.from(e as Map))).toList();
            _isLoadingLogs = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLogs = false);
    }
  }



  void _onSelectCamera(CameraItem cam) {
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

  void _onSelectRecording(Recording rec, [double startOffsetSeconds = 0.0]) {
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
    _notificationSub?.cancel();
    _cameraEventSub?.cancel();
    _archiveTimer?.cancel();
    super.dispose();
  }

  List<Recording> get _filteredRecordings {
    if (_filterPeriod == 'all') return _recordings;
    return _recordings.where((rec) {
      final hour = DateTime.tryParse(rec.startAt)?.hour ?? 0;
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
    final dateIsoFormatted = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: HubSightColors.bgDark,
      drawer: const AppSidebar(activeRoute: 'home'),
      appBar: AppBar(
        backgroundColor: HubSightColors.cardDark,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: HubSightColors.borderDark, width: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: HubSightColors.textPrimary),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: HubSightColors.primary,
                borderRadius: HubSightRadius.roundedXl,
              ),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.appTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: HubSightColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: HubSightColors.textSecondary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
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
              // 1. Top Video Player Area
              _buildVideoPlayerSection(isCamStopped, l10n),

              const SizedBox(height: 12),

              // 2. Camera Device & Date Picker Controls Card
              _buildControlsCard(dateFormatted, l10n),

              const SizedBox(height: 14),

              // 3. Event-based 24h Playback Timeline Dark Card
              _buildEventPlaybackSection(dateIsoFormatted, l10n),

              const SizedBox(height: 14),

              // 4. Face Recognition Logs Sidebar Section
              if (_selectedCam != null && _selectedCam!.enableAi)
                _buildRecognitionLogsSection(l10n),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. Video Player Section ---
  Widget _buildVideoPlayerSection(bool isStopped, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: 250,
      color: Colors.black,
      child: isStopped && _mode == 'live'
          ? _buildStoppedCameraState(l10n)
          : _mode == 'live'
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    WebRTCViewer(
                      cameraId: _selectedCam?.id ?? '',
                      enableAi: _selectedCam?.enableAi ?? true,
                      showBbox: _selectedCam?.showBbox ?? true,
                    ),
                    // LIVE Badge Pin
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 8),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, color: Colors.white, size: 8),
                            SizedBox(width: 6),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : _buildArchiveVideoPlayer(l10n),
    );
  }

  // --- Archive Video Player with YouTube-style Controls ---
  Widget _buildArchiveVideoPlayer(AppLocalizations l10n) {
    final progress = _archiveDurationSeconds > 0
        ? (_archiveCurrentSeconds / _archiveDurationSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Simulated video frame / poster
        Container(
          color: HubSightColors.bgDark,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam_rounded, size: 54, color: HubSightColors.primary),
                const SizedBox(height: 8),
                Text(
                  _activeRecording != null
                      ? _activeRecording!.startAt.replaceAll("T", " ")
                      : l10n.playingArchive,
                  style: const TextStyle(color: HubSightColors.textSecondary, fontSize: 12.5),
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
                // Start - End Segment Time
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: HubSightColors.surfaceDark,
                    borderRadius: HubSightRadius.roundedXl,
                    border: Border.all(color: HubSightColors.borderDark),
                  ),
                  child: Text(
                    _activeRecording?.startAt.split('T').last.split('.').first ?? '00:00:00',
                    style: const TextStyle(
                      color: HubSightColors.primaryLight,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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

                    // Speed Selector
                    PopupMenuButton<double>(
                      initialValue: _playbackSpeed,
                      onSelected: (rate) {
                        setState(() => _playbackSpeed = rate);
                      },
                      itemBuilder: (context) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((rate) {
                        return PopupMenuItem<double>(
                          value: rate,
                          child: Text('${rate}x', style: TextStyle(
                            fontWeight: _playbackSpeed == rate ? FontWeight.bold : FontWeight.normal,
                            color: _playbackSpeed == rate ? HubSightColors.primary : HubSightColors.textPrimary,
                          )),
                        );
                      }).toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: HubSightColors.surfaceDark,
                          borderRadius: HubSightRadius.roundedXl,
                          border: Border.all(color: HubSightColors.borderDark),
                        ),
                        child: Text(
                          '${_playbackSpeed}x',
                          style: const TextStyle(color: HubSightColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
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
                color: HubSightColors.surfaceDark,
                borderRadius: HubSightRadius.roundedCard,
                border: Border.all(color: HubSightColors.borderDark),
              ),
              child: const Icon(
                Icons.videocam_off_outlined,
                color: HubSightColors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.cameraStoppedStatus,
              style: const TextStyle(
                color: HubSightColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.cameraStoppedTitle(camName),
              style: const TextStyle(
                color: HubSightColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.cameraStoppedDesc,
              style: const TextStyle(
                color: HubSightColors.textSecondary,
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

  // --- 2. Camera Device & Date Selection Card ---
  Widget _buildControlsCard(String dateFormatted, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: HubSightColors.cardDark,
        borderRadius: HubSightRadius.roundedCard,
        border: Border.all(color: HubSightColors.borderDark),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Device Selector Pill
              Expanded(
                child: Row(
                  children: [
                    Text(
                      l10n.deviceLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: HubSightColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _showCameraPicker(l10n),
                        borderRadius: HubSightRadius.roundedXl,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: HubSightColors.surfaceDark,
                            borderRadius: HubSightRadius.roundedXl,
                            border: Border.all(color: HubSightColors.borderDark),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedCam?.name ?? l10n.selectCamera,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: HubSightColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 18, color: HubSightColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Date Picker Pill
              Expanded(
                child: Row(
                  children: [
                    Text(
                      l10n.dateLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: HubSightColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _showDatePicker(),
                        borderRadius: HubSightRadius.roundedXl,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: HubSightColors.surfaceDark,
                            borderRadius: HubSightRadius.roundedXl,
                            border: Border.all(color: HubSightColors.borderDark),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dateFormatted,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: HubSightColors.textPrimary,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 18, color: HubSightColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: HubSightColors.borderDark),
          const SizedBox(height: 10),

          // Recordings Summary Count
          Row(
            children: [
              Text(
                l10n.recordsLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: HubSightColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _isLoadingTimeline
                    ? l10n.loading
                    : (_recordings.isEmpty
                        ? l10n.noData
                        : l10n.recordsCount(_recordings.length)),
                style: const TextStyle(
                  fontSize: 12,
                  color: HubSightColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCameraPicker(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: HubSightColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: HubSightRadius.roundedSheet,
        side: BorderSide(color: HubSightColors.borderDark),
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
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: HubSightColors.textPrimary),
                ),
              ),
              const Divider(height: 1, color: HubSightColors.borderDark),
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
                                  : HubSightColors.textMuted,
                            ),
                            title: Text(cam.name,
                                style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? HubSightColors.primary
                                        : HubSightColors.textPrimary)),
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
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: HubSightColors.primary,
              surface: HubSightColors.cardDark,
              onSurface: HubSightColors.textPrimary,
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

  // --- 3. Event-based 24h Playback Timeline Section ---
  Widget _buildEventPlaybackSection(String dateIsoFormatted, AppLocalizations l10n) {
    final count = _recordings.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HubSightColors.cardDark,
        borderRadius: HubSightRadius.roundedCard,
        border: Border.all(color: HubSightColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Sparkles
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: HubSightColors.surfaceDark,
                  borderRadius: HubSightRadius.roundedXl,
                  border: Border.all(color: HubSightColors.borderDark),
                ),
                child: const Icon(Icons.auto_awesome, color: HubSightColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.eventTimelineTitle,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: HubSightColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      count == 0 ? l10n.noEventsToday : l10n.eventsToday(count),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: count == 0 ? const Color(0xFFFBBF24) : const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Filters Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: HubSightColors.bgDark,
                  borderRadius: HubSightRadius.roundedXl,
                  border: Border.all(color: HubSightColors.borderDark),
                ),
                child: Row(
                  children: [
                    _buildFilterTab('all', l10n.filterAll(count)),
                    _buildFilterTab('morning', l10n.filterMorning),
                    _buildFilterTab('afternoon', l10n.filterAfternoon),
                    _buildFilterTab('evening', l10n.filterEvening),
                  ],
                ),
              ),

              // Live Action Button
              InkWell(
                onTap: _handleGoLive,
                borderRadius: HubSightRadius.roundedXl,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _mode == 'live' ? HubSightColors.primary : HubSightColors.surfaceDark,
                    borderRadius: HubSightRadius.roundedXl,
                    border: Border.all(color: _mode == 'live' ? HubSightColors.primary : HubSightColors.borderDark),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.radio_button_checked, size: 12, color: _mode == 'live' ? Colors.white : HubSightColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Live',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _mode == 'live' ? Colors.white : HubSightColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 24h Timeline Bar
          Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('00:00', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: HubSightColors.textMuted)),
                  Text('06:00', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: HubSightColors.textMuted)),
                  Text('12:00', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: HubSightColors.textMuted)),
                  Text('18:00', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: HubSightColors.textMuted)),
                  Text('24:00', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: HubSightColors.textMuted)),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 32,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: HubSightColors.bgDark,
                  borderRadius: HubSightRadius.roundedXl,
                  border: Border.all(color: HubSightColors.borderDark),
                ),
                child: Stack(
                  children: [
                    for (final rec in _filteredRecordings) ...[
                      () {
                        final start = DateTime.tryParse(rec.startAt) ?? DateTime.now();
                        final totalSeconds = start.hour * 3600 + start.minute * 60 + start.second;
                        final leftRatio = (totalSeconds / 86400.0).clamp(0.0, 0.95);
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
                            markerColor = const Color(0xFF38BDF8);
                        }

                        return Positioned(
                          left: leftRatio * 300,
                          top: 3,
                          bottom: 3,
                          child: GestureDetector(
                            onTap: () => _onSelectRecording(rec),
                            child: Container(
                              width: 6,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : markerColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        );
                      }(),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Recordings Clips Grid / List
          if (_filteredRecordings.isNotEmpty) ...[
            const Divider(color: HubSightColors.borderDark),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredRecordings.length,
              itemBuilder: (context, index) {
                final rec = _filteredRecordings[index];
                final isSelected = _activeRecording?.id == rec.id;
                final duration = rec.durationSeconds > 0 ? rec.durationSeconds : 30;

                return InkWell(
                  onTap: () => _onSelectRecording(rec),
                  borderRadius: HubSightRadius.roundedXl,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? HubSightColors.surfaceElevated : HubSightColors.surfaceDark,
                      borderRadius: HubSightRadius.roundedXl,
                      border: Border.all(
                        color: isSelected ? HubSightColors.primary : HubSightColors.borderDark,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: HubSightColors.bgDark,
                            borderRadius: HubSightRadius.roundedXl,
                          ),
                          child: Icon(
                            isSelected ? Icons.play_arrow_rounded : Icons.videocam_outlined,
                            color: HubSightColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.recordingEvent(rec.eventType.toUpperCase()),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? HubSightColors.primaryLight : HubSightColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${rec.startAt.replaceAll("T", " ")} (${duration}s)',
                                style: const TextStyle(fontSize: 11, color: HubSightColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.graphic_eq_rounded, color: HubSightColors.primary, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // --- 4. Face Recognition Logs Sidebar Section ---
  Widget _buildRecognitionLogsSection(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HubSightColors.cardDark,
        borderRadius: HubSightRadius.roundedCard,
        border: Border.all(color: HubSightColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.face_retouching_natural_rounded, color: HubSightColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Nhật ký nhận diện khuôn mặt',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: HubSightColors.textPrimary),
                  ),
                ],
              ),
              Text(
                '${_recognitionLogs.length} sự kiện',
                style: const TextStyle(fontSize: 11.5, color: HubSightColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingLogs)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2, color: HubSightColors.primary)))
          else if (_recognitionLogs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: Text('Chưa có dữ liệu nhận diện khuôn mặt', style: TextStyle(color: HubSightColors.textMuted, fontSize: 12)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recognitionLogs.length.clamp(0, 5),
              itemBuilder: (context, index) {
                final log = _recognitionLogs[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: HubSightColors.surfaceDark,
                    backgroundImage: log.thumbnailUrl != null ? NetworkImage(log.thumbnailUrl!) : null,
                    child: log.thumbnailUrl == null ? const Icon(Icons.person, color: HubSightColors.textSecondary, size: 18) : null,
                  ),
                  title: Text(log.memberName ?? 'Người lạ', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: HubSightColors.textPrimary)),
                  subtitle: Text(log.createdAt, style: const TextStyle(fontSize: 11, color: HubSightColors.textMuted)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x2610B981),
                      borderRadius: HubSightRadius.roundedXl,
                      border: Border.all(color: const Color(0x4D10B981)),
                    ),
                    child: Text(
                      '${(log.confidence * 100).toInt()}%',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF34D399)),
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
      onTap: () => setState(() => _filterPeriod = key),
      borderRadius: HubSightRadius.roundedXl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? HubSightColors.surfaceElevated : Colors.transparent,
          borderRadius: HubSightRadius.roundedXl,
          border: isSelected ? Border.all(color: HubSightColors.borderDark) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? HubSightColors.primaryLight : HubSightColors.textMuted,
          ),
        ),
      ),
    );
  }
}
