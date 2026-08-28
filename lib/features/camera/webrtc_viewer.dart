import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

class WebRTCViewer extends ConsumerStatefulWidget {
  final String cameraId;
  
  const WebRTCViewer({super.key, required this.cameraId});

  @override
  ConsumerState<WebRTCViewer> createState() => _WebRTCViewerState();
}

class _WebRTCViewerState extends ConsumerState<WebRTCViewer> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  Timer? _heartbeatTimer;
  String? _poolStreamName;
  bool _isDisposed = false;
  
  @override
  void initState() {
    super.initState();
    initRenderers();
  }

  Future<void> initRenderers() async {
    await _localRenderer.initialize();
    _connectWebRTC();
  }
  
  Future<void> _connectWebRTC() async {
    try {
      final pc = await createPeerConnection({
        'iceServers': [],
      });
      _peerConnection = pc;

      // When the media stream arrives, attach it to the renderer
      pc.onTrack = (event) {
        if (event.track.kind == 'video') {
          _localRenderer.srcObject = event.streams[0];
        }
      };

      // Add a single sendrecv transceiver to tell go2rtc what we want
      await pc.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendRecv),
      );

      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      // Wait a moment for ICE gathering (or wait for iceGatheringState to be complete)
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_isDisposed) return;
      
      final client = ref.read(apiClientProvider).client;
      // Negotiate with WebRTC service via API Gateway Core Service interceptor
      final response = await client.post(
        '/live/\${widget.cameraId}/webrtc',
        data: pc.localDescription?.sdp,
        options: Options(
          headers: {'Content-Type': 'application/sdp'},
          responseType: ResponseType.plain,
        ),
      );
      
      final answerSdp = response.data.toString();
      _poolStreamName = response.headers.value('X-Pool-Stream-Name');

      final answer = RTCSessionDescription(answerSdp, 'answer');
      await pc.setRemoteDescription(answer);
      
      if (_poolStreamName != null && !_isDisposed) {
        _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
          client.post(
            '/live/\${widget.cameraId}/heartbeat',
            queryParameters: {'stream_name': _poolStreamName},
          ).catchError((_) {});
        });
      }
    } catch (e) {
      debugPrint('WebRTC error: \$e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _heartbeatTimer?.cancel();
    _peerConnection?.close();
    _localRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: RTCVideoView(_localRenderer),
    );
  }
}


