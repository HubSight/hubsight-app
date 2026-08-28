import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/socket_service.dart';
import '../../core/network/api_client.dart';
import '../camera/webrtc_viewer.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  List<dynamic> _cameras = [];
  bool _isLoading = true;
  StreamSubscription? _notificationSub;

  @override
  void initState() {
    super.initState();
    _initData();
  }
  
  Future<void> _initData() async {
    // 1. Fetch REST API
    try {
      final cameras = await ref.read(apiClientProvider).getCameras();
      if (mounted) {
        setState(() {
          _cameras = cameras;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load cameras: \$e');
      if (mounted) setState(() => _isLoading = false);
    }
    
    // 2. Connect WebSockets
    final socketService = ref.read(socketServiceProvider);
    socketService.connect();
    
    // 3. Listen to Real-time Notifications
    _notificationSub = socketService.onNotification.listen((data) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alert: \${data['type'] ?? 'Unknown'}'),
          backgroundColor: Colors.redAccent,
        )
      );
    });
  }
  
  @override
  void dispose() {
    _notificationSub?.cancel();
    ref.read(socketServiceProvider).disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _cameras.isEmpty 
          ? Center(child: Text(l10n.dashboardNoCameras))
          : ListView.builder(
              itemCount: _cameras.length,
              itemBuilder: (context, index) {
                final cam = _cameras[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.videocam),
                        title: Text(cam['name'] ?? 'Camera \${cam['id']}'),
                        subtitle: Text(cam['status'] ?? l10n.cameraOffline),
                      ),
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        // Render WebRTC when active, else placeholder
                        child: cam['status'] == 'active' || cam['status'] == 'online'
                          ? WebRTCViewer(cameraId: cam['id'].toString())
                          : Center(child: Text(l10n.cameraOffline)),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}



