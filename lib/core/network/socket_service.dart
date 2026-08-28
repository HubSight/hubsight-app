import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_service.dart';

final socketServiceProvider = Provider((ref) {
  final storage = ref.watch(storageServiceProvider);
  final serverUrl = storage.getServerUrl() ?? 'http://10.0.2.2:8088';
  return SocketService(serverUrl: serverUrl);
});

class SocketService {
  IO.Socket? _socket;
  String _serverUrl;
  
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotification => _notificationController.stream;

  final _cameraEventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onCameraEvent => _cameraEventController.stream;
  
  SocketService({String serverUrl = 'http://10.0.2.2:8088'}) : _serverUrl = serverUrl;

  String get relayUrl => '${_serverUrl.replaceAll(RegExp(r'/+$'), '')}/relay';

  void updateServerUrl(String newServerUrl) {
    _serverUrl = newServerUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (_socket != null && _socket!.connected) {
      disconnect();
      connect();
    }
  }

  void connect() {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(relayUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build()
    );

    _socket!.connect();
    
    _socket!.onConnect((_) {
      print('Connected to Socket.IO relay at $relayUrl');
    });
    
    _socket!.on('notification.new', (data) {
      if (data != null && data is Map) {
        _notificationController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('camera.stopped', (data) {
      if (data != null && data is Map) {
        final map = Map<String, dynamic>.from(data);
        map['event_type'] = 'camera.stopped';
        _cameraEventController.add(map);
      }
    });

    _socket!.on('camera.started', (data) {
      if (data != null && data is Map) {
        final map = Map<String, dynamic>.from(data);
        map['event_type'] = 'camera.started';
        _cameraEventController.add(map);
      }
    });

    _socket!.on('camera.updated', (data) {
      if (data != null && data is Map) {
        final map = Map<String, dynamic>.from(data);
        map['event_type'] = 'camera.updated';
        _cameraEventController.add(map);
      }
    });

    _socket!.onDisconnect((_) => print('Disconnected from Socket.IO relay'));
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
