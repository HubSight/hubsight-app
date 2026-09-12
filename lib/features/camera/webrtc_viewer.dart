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
  final bool enableAi;
  final bool showBbox;
  final ValueChanged<bool>? onLiveStatusChange;

  const WebRTCViewer({
    super.key,
    required this.cameraId,
    this.enableAi = true,
    this.showBbox = true,
    this.onLiveStatusChange,
  });

  @override
  ConsumerState<WebRTCViewer> createState() => _WebRTCViewerState();
}

class _WebRTCViewerState extends ConsumerState<WebRTCViewer> {
  HubSightWebRTCManager? _rtcManager;
  RTCVideoRenderer? _renderer;
  StreamSubscription? _statusSub;
  StreamSubscription? _socketSub;

  bool _isInitializing = true;
  String? _errorMessage;
  bool _isMuted = true;
  bool _showTrace = false;

  List<OverlayBox> _boxes = [];

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant WebRTCViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cameraId != widget.cameraId) {
      _disposeCurrentManager();
      _initStream();
    }
  }

  void _initStream() {
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
      _errorMessage = null;
    });
    widget.onLiveStatusChange?.call(false);

    _rtcManager = sdk.createWebRTCManager(widget.cameraId);

    _statusSub = _rtcManager!.onStatusChanged.listen((status) {
      if (!mounted) return;
      if (status == StreamStatus.connected) {
        setState(() {
          _isInitializing = false;
          _renderer = _rtcManager!.renderer;
        });
        widget.onLiveStatusChange?.call(true);
      } else if (status == StreamStatus.failed) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Không thể kết nối luồng trực tiếp.';
        });
        widget.onLiveStatusChange?.call(false);
      }
    });

    _rtcManager!.startStream().then((renderer) {
      if (mounted) {
        setState(() {
          _renderer = renderer;
          _isInitializing = false;
        });
        widget.onLiveStatusChange?.call(true);
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Lỗi kết nối camera: $e';
        });
        widget.onLiveStatusChange?.call(false);
      }
    });

    // Listen to AI bounding box events
    _socketSub = sdk.relay.onAIAlert.listen((event) {
      if (!mounted || event.cameraId != widget.cameraId) return;
      if (event.rawPayload != null && event.rawPayload!['boxes'] is List) {
        final rawBoxes = event.rawPayload!['boxes'] as List;
        setState(() {
          _boxes = rawBoxes
              .map((b) => OverlayBox.fromJson(Map<String, dynamic>.from(b as Map)))
              .toList();
        });
      }
    });
  }

  void _disposeCurrentManager() {
    _statusSub?.cancel();
    _socketSub?.cancel();
    _rtcManager?.stopStream();
    _rtcManager = null;
    _renderer = null;
  }

  @override
  void dispose() {
    _disposeCurrentManager();
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
    final fallenCount = _boxes.where((b) => b.state == 'fall').length;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. RTC Video Renderer
          if (!_isInitializing && _errorMessage == null && _renderer != null)
            RTCVideoView(
              _renderer!,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
            ),

          // 2. AI Bounding Box Overlays
          if (widget.enableAi && widget.showBbox && _boxes.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: BoundingBoxPainter(boxes: _boxes),
              ),
            ),

          // 3. Fall Detected Banner
          if (fallenCount > 0)
            Positioned(
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
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _disposeCurrentManager();
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

          // 6. Bottom Controls (Mute / Trace / AI Badge)
          if (!_isInitializing && _errorMessage == null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Row(
                children: [
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
                    onTap: () => setState(() => _showTrace = !_showTrace),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _showTrace ? const Color(0xFFE85D10) : Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.query_stats, color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text(
                            'Trace',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

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
              ),
            ),

          // 7. Trace HUD Panel
          if (_showTrace && !_isInitializing && _errorMessage == null)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WEBRTC STREAM TRACE',
                      style: TextStyle(
                        color: Color(0xFFF97316),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('Protocol: WebRTC (WHEP)', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    Text('Heartbeat: 30s Gateway ping', style: TextStyle(color: Colors.white70, fontSize: 10)),
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

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = box.state == 'fall' ? 3.0 : 2.0;

      canvas.drawRect(rect, paint);

      if (box.keypoints != null && box.keypoints!.length >= 17) {
        final kpts = box.keypoints!;
        final linePaint = Paint()
          ..color = color
          ..strokeWidth = 1.5;

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
                linePaint,
              );
            }
          }
        }

        final pointPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        for (final kp in kpts) {
          if (kp.length >= 3 && kp[2] > 0.3) {
            canvas.drawCircle(Offset(kp[0] * size.width, kp[1] * size.height), 2.5, pointPaint);
          }
        }
      }

      final label = box.name ?? box.state ?? '';
      if (label.isNotEmpty) {
        final textSpan = TextSpan(
          text: ' $label ',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        final badgeRect = Rect.fromLTWH(
          rect.left,
          (rect.top - 16).clamp(0.0, size.height - 16),
          textPainter.width + 4,
          16,
        );

        final badgePaint = Paint()..color = color;
        canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(3)), badgePaint);
        textPainter.paint(canvas, Offset(badgeRect.left + 2, badgeRect.top + 1));
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.boxes != boxes;
  }
}
