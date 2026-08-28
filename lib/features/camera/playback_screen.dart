import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/network/socket_service.dart';
import 'models/camera_models.dart';
import 'webrtc_viewer.dart';
import '../notifications/notification_screen.dart';
import '../common/app_sidebar.dart';

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
  List<Recording> _recordings = [];
  Recording? _activeRecording;
  
  bool _isLoadingCameras = true;
  bool _isLoadingTimeline = false;
  
  // Mode: 'live' | 'archive'
  String _mode = 'live';
  String _filterPeriod = 'all'; // 'all', 'morning', 'afternoon', 'evening'
  bool _isTimelineCollapsed = false;

  StreamSubscription? _notificationSub;
  StreamSubscription? _cameraEventSub;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // 1. Fetch Cameras
    await _fetchCameras();

    // 2. Connect Socket & Listen to events
    final socketService = ref.read(socketServiceProvider);
    socketService.connect();

    _notificationSub = socketService.onNotification.listen((data) {
      if (!mounted) return;
      final type = data['type'] ?? 'Alert';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Thông báo: $type')),
            ],
          ),
          backgroundColor: const Color(0xFFE85D10),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    });

    _cameraEventSub = socketService.onCameraEvent.listen((data) {
      if (!mounted) return;
      final eventType = data['event_type'];
      final camId = data['id']?.toString();
      
      setState(() {
        _cameras = _cameras.map((c) {
          if (c.id == camId) {
            final isStopped = eventType == 'camera.stopped' || (data['is_stopped'] == true);
            final updatedName = data['name'] ?? c.name;
            return CameraItem(
              id: c.id,
              name: updatedName,
              host: c.host,
              brand: c.brand,
              isActive: c.isActive,
              isStopped: isStopped,
              enableAi: c.enableAi,
              showBbox: c.showBbox,
            );
          }
          return c;
        }).toList();

        if (_selectedCam?.id == camId) {
          final isStopped = eventType == 'camera.stopped' || (data['is_stopped'] == true);
          _selectedCam = CameraItem(
            id: _selectedCam!.id,
            name: data['name'] ?? _selectedCam!.name,
            host: _selectedCam!.host,
            brand: _selectedCam!.brand,
            isActive: _selectedCam!.isActive,
            isStopped: isStopped,
            enableAi: _selectedCam!.enableAi,
            showBbox: _selectedCam!.showBbox,
          );
        }
      });
    });
  }

  Future<void> _fetchCameras() async {
    setState(() => _isLoadingCameras = true);
    try {
      final cameras = await ref.read(apiClientProvider).getCameras();
      if (mounted) {
        setState(() {
          _cameras = cameras;
          if (cameras.isNotEmpty && _selectedCam == null) {
            // Prefer running camera if available, else first camera
            _selectedCam = cameras.firstWhere(
              (c) => !c.isStopped,
              orElse: () => cameras.first,
            );
          }
          _isLoadingCameras = false;
        });

        if (_selectedCam != null) {
          _fetchTimeline();
        }
      }
    } catch (e) {
      debugPrint('Error fetching cameras: $e');
      if (mounted) {
        // Fallback demo camera if backend has not yet populated cameras
        if (_cameras.isEmpty) {
          final fallbackCam = CameraItem(
            id: 'cam_facetime',
            name: 'Facetime HD Cam',
            isStopped: true,
          );
          setState(() {
            _cameras = [fallbackCam];
            _selectedCam = fallbackCam;
            _isLoadingCameras = false;
          });
        } else {
          setState(() => _isLoadingCameras = false);
        }
      }
    }
  }

  Future<void> _fetchTimeline() async {
    if (_selectedCam == null) return;
    setState(() => _isLoadingTimeline = true);
    try {
      final recordings = await ref.read(apiClientProvider).getTimelineRecordings(
        _selectedCam!.id,
        _selectedDate,
      );
      if (mounted) {
        setState(() {
          _recordings = recordings;
          _isLoadingTimeline = false;
          if (recordings.isNotEmpty && _mode == 'archive') {
            _activeRecording = recordings.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching timeline: $e');
      if (mounted) setState(() => _isLoadingTimeline = false);
    }
  }

  void _onSelectCamera(CameraItem camera) {
    setState(() {
      _selectedCam = camera;
      _mode = 'live';
      _activeRecording = null;
    });
    _fetchTimeline();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE85D10),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchTimeline();
    }
  }

  void _showCameraPickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.selectCamera,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: _cameras.length,
                    itemBuilder: (context, index) {
                      final cam = _cameras[index];
                      final isSelected = cam.id == _selectedCam?.id;
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE85D10).withOpacity(0.1)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            cam.isStopped ? Icons.videocam_off_outlined : Icons.videocam_outlined,
                            color: isSelected
                                ? const Color(0xFFE85D10)
                                : (cam.isStopped ? Colors.grey : const Color(0xFF10B981)),
                          ),
                        ),
                        title: Text(
                          cam.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: Text(
                          cam.isStopped ? l10n.cameraStopped : l10n.cameraOnline,
                          style: TextStyle(
                            fontSize: 12,
                            color: cam.isStopped ? const Color(0xFF94A3B8) : const Color(0xFF10B981),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFFE85D10))
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
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    _cameraEventSub?.cancel();
    super.dispose();
  }

  List<Recording> get _filteredRecordings {
    if (_filterPeriod == 'all') return _recordings;
    return _recordings.filterByPeriod(_filterPeriod);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormatted = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final dateIsoFormatted = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final isCamStopped = _selectedCam?.isStopped ?? true;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppSidebar(activeRoute: 'home'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE85D10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'HubSight',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Color(0xFF475569)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF475569)),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchCameras();
          await _fetchTimeline();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Video Area (Player / Offline Screen)
              _buildVideoPlayerSection(isCamStopped, l10n),

              const SizedBox(height: 12),

              // 2. Camera Device & Date Selection Card
              _buildControlsCard(dateFormatted, l10n),

              const SizedBox(height: 14),

              // 3. Event-based Playback Dark Card
              _buildEventPlaybackSection(dateIsoFormatted, l10n),

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
      child: isStopped
          ? _buildStoppedCameraState(l10n)
          : _mode == 'live'
              ? Stack(
                  children: [
                    WebRTCViewer(cameraId: _selectedCam!.id),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.circle, color: Colors.white, size: 8),
                            SizedBox(width: 5),
                            Text(
                              'LIVE',
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
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_circle_fill, size: 64, color: Color(0xFFE85D10)),
                      const SizedBox(height: 8),
                      Text(
                        _activeRecording != null
                            ? '${l10n.playingArchive}: ${_activeRecording!.startAt}'
                            : l10n.playingArchive,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
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
            // Dark icon container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2430),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2D3748), width: 1),
              ),
              child: const Icon(
                Icons.videocam_off_outlined,
                color: Color(0xFFCBD5E1),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            // Tag
            Text(
              l10n.cameraStoppedStatus,
              style: const TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              '“$camName” đã tắt',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              l10n.cameraStoppedDesc,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12.5,
                height: 1.4,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Camera Selector
          Row(
            children: [
              const Icon(Icons.camera_alt_outlined, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                l10n.deviceLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _showCameraPickerModal,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            _selectedCam?.name ?? 'Chọn camera',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8), size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Date Selector
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                l10n.dateLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateFormatted,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8), size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 3: Records info
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                l10n.recordsLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _recordings.isEmpty
                    ? l10n.noData
                    : l10n.recordsCount(_recordings.length),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3. Event-based Playback Dark Card ---
  Widget _buildEventPlaybackSection(String dateIsoFormatted, AppLocalizations l10n) {
    final count = _recordings.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark Slate / Navy
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF27190F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF5E3211)),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFF97316),
                  size: 20,
                ),
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
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 11, color: Color(0xFFF97316)),
                          const SizedBox(width: 4),
                          Text(
                            dateIsoFormatted,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      count == 0
                          ? l10n.noEventsToday
                          : l10n.eventsToday(count),
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

          // Filters & Live Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Period Filter Tabs
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF020617),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E293B)),
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

              // Live Stream Button / Toggle
              InkWell(
                onTap: () {
                  setState(() {
                    _mode = 'live';
                    _activeRecording = null;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _mode == 'live' ? const Color(0xFFF97316) : const Color(0xFF334155),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _mode == 'live' ? const Color(0xFFF97316) : const Color(0xFF64748B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.sensors,
                        size: 13,
                        color: _mode == 'live' ? const Color(0xFFF97316) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.live,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: _mode == 'live' ? const Color(0xFFF97316) : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_up, size: 14, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 24-Hour Timeline Bar
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('00:00', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8))),
                    Text('03:00', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8))),
                    Text('06:00', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8))),
                    Text('09:00', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8))),
                    Text('12:00', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8))),
                    Text('15:00', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8))),
                    Text('18:00', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8))),
                    Text('21:00', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8))),
                    Text('24:00', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Timeline Bar Track
              Container(
                height: 36,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF020617),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Stack(
                  children: [
                    // Vertical grid lines
                    Row(
                      children: List.generate(24, (index) {
                        return Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: const Color(0xFF1E293B).withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    // Event Markers
                    ..._filteredRecordings.map((rec) {
                      final start = DateTime.tryParse(rec.startAt) ?? DateTime.now();
                      final totalSeconds = start.hour * 3600 + start.minute * 60 + start.second;
                      final leftRatio = (totalSeconds / 86400.0).clamp(0.0, 0.98);

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

                      final isSelected = _activeRecording?.id == rec.id;

                      return Positioned(
                        left: leftRatio * 320, // Approx width percentage
                        top: 4,
                        bottom: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _mode = 'archive';
                              _activeRecording = rec;
                            });
                          },
                          child: Container(
                            width: 8,
                            decoration: BoxDecoration(
                              color: markerColor,
                              borderRadius: BorderRadius.circular(4),
                              border: isSelected ? Border.all(color: Colors.white, width: 1.5) : null,
                              boxShadow: [
                                BoxShadow(
                                  color: markerColor.withOpacity(0.6),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Recordings list if any
          if (_filteredRecordings.isNotEmpty) ...[
            const Divider(color: Color(0xFF1E293B)),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredRecordings.length,
              itemBuilder: (context, index) {
                final rec = _filteredRecordings[index];
                final isSelected = _activeRecording?.id == rec.id;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.videocam, color: Color(0xFFF97316), size: 20),
                  ),
                  title: Text(
                    l10n.recordingEvent(rec.eventType.toUpperCase()),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFFF97316) : Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    '${rec.startAt} (${rec.durationSeconds}s)',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      isSelected ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: const Color(0xFFF97316),
                    ),
                    onPressed: () {
                      setState(() {
                        _mode = 'archive';
                        _activeRecording = rec;
                      });
                    },
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterTab(String key, String label) {
    final isSelected = _filterPeriod == key;

    return InkWell(
      onTap: () => setState(() => _filterPeriod = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: const Color(0xFF334155)) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFFFB923C) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

extension RecordingFilter on List<Recording> {
  List<Recording> filterByPeriod(String period) {
    return where((rec) {
      final start = DateTime.tryParse(rec.startAt);
      if (start == null) return true;
      final hour = start.hour;
      if (period == 'morning') return hour >= 0 && hour < 12;
      if (period == 'afternoon') return hour >= 12 && hour < 18;
      if (period == 'evening') return hour >= 18 && hour < 24;
      return true;
    }).toList();
  }
}

