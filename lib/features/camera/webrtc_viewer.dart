import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';
import '../../core/network/sdk_provider.dart';

class OverlayBox {
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final String? state;
  final String? name;
  final int? trackId;
  final List<List<double>>? keypoints;

  OverlayBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    this.state,
    this.name,
    this.trackId,
    this.keypoints,
  });

  factory OverlayBox.fromJson(Map<String, dynamic> json) {
    List<List<double>>? kpts;
    if (json['keypoints'] is List) {
      kpts = (json['keypoints'] as List).map((e) {
        if (e is List) {
          return e.map((val) => (val as num).toDouble()).toList();
        }
        return <double>[];
      }).toList();
    }

    return OverlayBox(
      x1: (json['x1'] as num?)?.toDouble() ?? 0.0,
      y1: (json['y1'] as num?)?.toDouble() ?? 0.0,
      x2: (json['x2'] as num?)?.toDouble() ?? 0.0,
      y2: (json['y2'] as num?)?.toDouble() ?? 0.0,
      state: json['state']?.toString(),
      name: json['name']?.toString(),
      trackId: json['track_id'] is int ? json['track_id'] : null,
      keypoints: kpts,
    );
  }
}

class WebRTCViewer extends ConsumerStatefulWidget {
  final String cameraId;
  final String? cameraName;
  final bool enableAi;
  final bool showBbox;
  final ValueChanged<bool>? onLiveStatusChange;
  final bool isFullscreen;
  final VoidCallback? onToggleFullscreen;
  final int streamReloadIndex;
  final bool hasPtz;
  final VoidCallback? onOpenPtz;

  const WebRTCViewer({
    super.key,
    required this.cameraId,
    this.cameraName,
    this.enableAi = true,
    this.showBbox = true,
    this.onLiveStatusChange,
    this.isFullscreen = false,
    this.onToggleFullscreen,
    this.streamReloadIndex = 0,
    this.hasPtz = false,
    this.onOpenPtz,
  });

  @override
  ConsumerState<WebRTCViewer> createState() => _WebRTCViewerState();
}

class _WebRTCViewerState extends ConsumerState<WebRTCViewer> {
  HubSightWebRTCManager? _rtcManager;
  RTCVideoRenderer? _renderer;
  StreamSubscription? _statusSub;
  StreamSubscription? _socketSub;
  Timer? _boxExpiryTimer;
  DateTime? _lastBoxUpdateTime;

  bool _isInitializing = true;
  String? _errorMessage;
  bool _isMuted = true;
  int _retryCount = 0;
  static const int _maxAutoRetries = 2;
  Timer? _retryTimer;
  bool _showFullscreenPtzPad = false;

  final ValueNotifier<List<OverlayBox>> _boxesNotifier = ValueNotifier<List<OverlayBox>>([]);

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant WebRTCViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cameraId != widget.cameraId ||
        oldWidget.streamReloadIndex != widget.streamReloadIndex) {
      _disposeCurrentManager();
      _retryCount = 0;
      _initStream();
    }
  }

  String _formatErrorMessage(dynamic error) {
    final str = error.toString();
    if (str.contains('502') || str.contains('503') || str.contains('connection refused') || str.contains('Bad Gateway')) {
      return 'Máy chủ hoặc kết nối camera đang tạm thời gián đoạn (502 Bad Gateway). Đang thử lại...';
    } else if (str.contains('404') || str.contains('not found')) {
      return 'Camera không tồn tại hoặc đã bị gỡ khỏi hệ thống.';
    } else if (str.contains('401') || str.contains('403')) {
      return 'Phiên đăng nhập đã hết hạn hoặc không có quyền xem camera này.';
    } else if (str.contains('SocketException') || str.contains('TimeoutException')) {
      return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại kết nối mạng.';
    }
    return 'Lỗi kết nối camera: $error';
  }

  void _handleStreamError(dynamic error) {
    widget.onLiveStatusChange?.call(false);
    if (_retryCount < _maxAutoRetries) {
      _retryCount++;
      setState(() {
        _isInitializing = true;
        _errorMessage = 'Đang tự động kết nối lại luồng video ($_retryCount/$_maxAutoRetries)...';
      });
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          _disposeCurrentManager();
          _initStream(isRetry: true);
        }
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
        _errorMessage = _formatErrorMessage(error);
      });
    }
  }

  void _initStream({bool isRetry = false}) {
    if (!isRetry) {
      _retryCount = 0;
    }
    _retryTimer?.cancel();

    final sdk = ref.read(hubsightSdkProvider);
    if (sdk == null) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'SDK chưa được khởi tạo';
      });
      return;
    }

    setState(() {
      _isInitializing = true;
      if (!isRetry) _errorMessage = null;
    });
    widget.onLiveStatusChange?.call(false);

    _rtcManager = sdk.createWebRTCManager(widget.cameraId);

    _statusSub = _rtcManager!.onStatusChanged.listen((status) {
      if (!mounted) return;
      if (status == StreamStatus.connected) {
        setState(() {
          _isInitializing = false;
          _errorMessage = null;
          _renderer = _rtcManager!.renderer;
          _retryCount = 0;
        });
        widget.onLiveStatusChange?.call(true);
      } else if (status == StreamStatus.failed) {
        _handleStreamError('Không thể kết nối luồng trực tiếp.');
      }
    });

    _rtcManager!.startStream().then((renderer) {
      if (mounted) {
        setState(() {
          _renderer = renderer;
          _isInitializing = false;
          _errorMessage = null;
          _retryCount = 0;
        });
        widget.onLiveStatusChange?.call(true);
      }
    }).catchError((e) {
      if (mounted) {
        _handleStreamError(e);
      }
    });

    // Listen to AI bounding box events (updates ValueNotifier without triggering full widget rebuilds)
    _socketSub = sdk.relay.onAIAlert.listen((event) {
      if (!mounted || event.cameraId != widget.cameraId) return;
      if (event.rawPayload != null && event.rawPayload!['boxes'] is List) {
        final rawBoxes = event.rawPayload!['boxes'] as List;
        final now = DateTime.now();

        // Throttle updates to ~25fps (40ms) to ensure smooth 60fps UI rendering
        if (_lastBoxUpdateTime != null &&
            now.difference(_lastBoxUpdateTime!).inMilliseconds < 40) {
          return;
        }
        _lastBoxUpdateTime = now;

        if (rawBoxes.isEmpty && _boxesNotifier.value.isEmpty) {
          return;
        }

        _boxesNotifier.value = rawBoxes
            .map((b) => OverlayBox.fromJson(Map<String, dynamic>.from(b as Map)))
            .toList();

        // Auto-clear stale bounding boxes after 1.5s if detection stops
        _boxExpiryTimer?.cancel();
        if (rawBoxes.isNotEmpty) {
          _boxExpiryTimer = Timer(const Duration(milliseconds: 1500), () {
            if (mounted) {
              _boxesNotifier.value = [];
            }
          });
        }
      }
    });
  }

  void _disposeCurrentManager() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _statusSub?.cancel();
    _socketSub?.cancel();
    _boxExpiryTimer?.cancel();
    _rtcManager?.stopStream();
    _rtcManager = null;
    _renderer = null;
    _boxesNotifier.value = [];
  }

  @override
  void dispose() {
    _disposeCurrentManager();
    _boxesNotifier.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_renderer?.srcObject != null) {
        final audioTracks = _renderer!.srcObject!.getAudioTracks();
        for (var track in audioTracks) {
          track.enabled = !_isMuted;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. RTC Video Renderer (Isolated in RepaintBoundary to eliminate frame composite jank)
          if (!_isInitializing && _errorMessage == null && _renderer != null)
            RepaintBoundary(
              child: RTCVideoView(
                _renderer!,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                filterQuality: FilterQuality.none,
              ),
            ),

          // 2. AI Bounding Box Overlays (Isolated RepaintBoundary driven by ValueNotifier)
          if (widget.enableAi && widget.showBbox)
            Positioned.fill(
              child: RepaintBoundary(
                child: ValueListenableBuilder<List<OverlayBox>>(
                  valueListenable: _boxesNotifier,
                  builder: (context, boxes, _) {
                    if (boxes.isEmpty) return const SizedBox.shrink();
                    return CustomPaint(
                      painter: BoundingBoxPainter(boxes: boxes),
                    );
                  },
                ),
              ),
            ),

          // 3. Fall Detected Banner (Isolated builder - does not trigger full viewer rebuild)
          ValueListenableBuilder<List<OverlayBox>>(
            valueListenable: _boxesNotifier,
            builder: (context, boxes, _) {
              final fallenCount = boxes.where((b) => b.state == 'fall').length;
              if (fallenCount == 0) return const SizedBox.shrink();
              return Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'CẢNH BÁO: TÉ NGÃ ($fallenCount)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 4. Loading Overlay
          if (_isInitializing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFFE85D10),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Đang kết nối WebRTC (WHEP)...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Error Overlay with Retry
          if (_errorMessage != null)
            Container(
              color: const Color(0xFF0F172A),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 44),
                    const SizedBox(height: 10),
                    const Text(
                      'Luồng trực tiếp không khả dụng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _disposeCurrentManager();
                        _retryCount = 0;
                        _initStream();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE85D10),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Thử lại', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

          // 6. Bottom Controls (AI Badge / Mute / Fullscreen)
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              children: [
                if (!_isInitializing && _errorMessage == null) ...[
                  if (widget.enableAi)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B0764).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Color(0xFFC084FC), size: 12),
                          SizedBox(width: 4),
                          Text(
                            'AI Vision',
                            style: TextStyle(
                              color: Color(0xFFE9D5FF),
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  InkWell(
                    onTap: _toggleMute,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Icon(
                        _isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],

                if (widget.hasPtz) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    key: const Key('webrtc-ptz-button'),
                    onTap: () {
                      if (widget.isFullscreen) {
                        setState(() => _showFullscreenPtzPad = !_showFullscreenPtzPad);
                      } else {
                        widget.onOpenPtz?.call();
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _showFullscreenPtzPad
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.8)
                            : Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _showFullscreenPtzPad ? const Color(0xFF60A5FA) : Colors.white24,
                        ),
                      ),
                      child: const Icon(
                        Icons.control_camera_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],

                if (widget.onToggleFullscreen != null) ...[
                  if (!_isInitializing && _errorMessage == null) const SizedBox(width: 6),
                  InkWell(
                    key: const Key('webrtc-fullscreen-button'),
                    onTap: widget.onToggleFullscreen,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Icon(
                        widget.isFullscreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Fullscreen Floating PTZ Controller Pad Overlay
          if (widget.isFullscreen && widget.hasPtz && _showFullscreenPtzPad)
            Positioned(
              right: 16,
              bottom: 48,
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    HubSightPtzPad(
                      key: const Key('fullscreen-ptz-pad'),
                      cameraId: widget.cameraId,
                      cameraService: ref.read(hubsightSdkProvider)?.cameras,
                      buttonSize: 38.0,
                      iconSize: 20.0,
                      spacing: 6.0,
                      padding: const EdgeInsets.all(10.0),
                      borderRadius: 18.0,
                      backgroundColor: Colors.black.withValues(alpha: 0.8),
                      buttonColor: Colors.white.withValues(alpha: 0.15),
                      buttonBorderColor: Colors.white24,
                      iconColor: Colors.white,
                      stopButtonColor: Colors.red.withValues(alpha: 0.3),
                      stopIconColor: Colors.redAccent,
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: InkWell(
                        onTap: () => setState(() => _showFullscreenPtzPad = false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white70, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Fullscreen Top Bar (Back button, Camera name, Live status)
          if (widget.isFullscreen)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      key: const Key('fullscreen-back-button'),
                      onTap: widget.onToggleFullscreen,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                      widget.cameraName ?? 'LIVE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<OverlayBox> boxes;

  BoundingBoxPainter({required this.boxes});

  static const Map<String, Color> _boxColors = {
    'family': Color(0xFF10B981),
    'guest': Color(0xFF3B82F6),
    'stranger': Color(0xFFEF4444),
    'danger': Color(0xFFF97316),
    'fall': Color(0xFFF43F5E),
    'verifying': Color(0xFF94A3B8),
  };

  static const List<List<int>> _poseSkeleton = [
    [5, 6], [5, 7], [7, 9], [6, 8], [8, 10],
    [5, 11], [6, 12], [11, 12],
    [11, 13], [13, 15], [12, 14], [14, 16],
    [0, 1], [0, 2], [1, 3], [2, 4], [0, 5], [0, 6],
  ];

  // Reusable static Paint instances to eliminate object allocation & GC churn in paint loop
  static final Paint _boxPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _pointPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _linePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5;
  static final Paint _badgePaint = Paint()..style = PaintingStyle.fill;

  // Cached TextPainter instances by label to eliminate repeated font shaping and layout calculations
  static final Map<String, TextPainter> _textPainterCache = {};

  @override
  void paint(Canvas canvas, Size size) {
    for (final box in boxes) {
      final color = _boxColors[box.state] ?? const Color(0xFF38BDF8);

      final rect = Rect.fromLTRB(
        box.x1 * size.width,
        box.y1 * size.height,
        box.x2 * size.width,
        box.y2 * size.height,
      );

      _boxPaint
        ..color = color
        ..strokeWidth = box.state == 'fall' ? 3.0 : 2.0;
      canvas.drawRect(rect, _boxPaint);

      if (box.keypoints != null && box.keypoints!.length >= 17) {
        final kpts = box.keypoints!;
        _linePaint.color = color;

        for (final pair in _poseSkeleton) {
          final a = pair[0];
          final b = pair[1];
          if (a < kpts.length && b < kpts.length) {
            final pa = kpts[a];
            final pb = kpts[b];
            if (pa.length >= 3 && pb.length >= 3 && pa[2] > 0.3 && pb[2] > 0.3) {
              canvas.drawLine(
                Offset(pa[0] * size.width, pa[1] * size.height),
                Offset(pb[0] * size.width, pb[1] * size.height),
                _linePaint,
              );
            }
          }
        }

        _pointPaint.color = color;
        for (final kp in kpts) {
          if (kp.length >= 3 && kp[2] > 0.3) {
            canvas.drawCircle(Offset(kp[0] * size.width, kp[1] * size.height), 2.5, _pointPaint);
          }
        }
      }

      final label = box.name ?? box.state ?? '';
      if (label.isNotEmpty) {
        var textPainter = _textPainterCache[label];
        if (textPainter == null) {
          final textSpan = TextSpan(
            text: ' $label ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          );
          textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          )..layout();
          _textPainterCache[label] = textPainter;
        }

        final badgeRect = Rect.fromLTWH(
          rect.left,
          (rect.top - 16).clamp(0.0, size.height - 16),
          textPainter.width + 4,
          16,
        );

        _badgePaint.color = color;
        canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(3)), _badgePaint);
        textPainter.paint(canvas, Offset(badgeRect.left + 2, badgeRect.top + 1));
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    if (oldDelegate.boxes.isEmpty && boxes.isEmpty) return false;
    return oldDelegate.boxes != boxes;
  }
}
