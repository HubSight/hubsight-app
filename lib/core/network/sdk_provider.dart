import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';

/// Provider for the maintenance mode state triggered by Kill-Switch (HTTP 503).
final maintenanceStateProvider =
    StateNotifierProvider<MaintenanceNotifier, MaintenanceException?>(
  (ref) => MaintenanceNotifier(),
);

class MaintenanceNotifier extends StateNotifier<MaintenanceException?> {
  MaintenanceNotifier([super.state]);

  void setMaintenance(MaintenanceException ex) {
    state = ex;
  }

  void clear() {
    state = null;
  }
}

/// Provider signaling when a session was revoked remotely via Relay.
final remoteRevocationEventProvider =
    StateNotifierProvider<RemoteRevocationNotifier, bool>(
  (ref) => RemoteRevocationNotifier(),
);

class RemoteRevocationNotifier extends StateNotifier<bool> {
  RemoteRevocationNotifier() : super(false);

  void trigger() => state = true;
  void reset() => state = false;
}

/// State notifier managing the active [HubSightSDK] instance lifecycle.
class SdkStateNotifier extends StateNotifier<HubSightSDK?> {
  final Ref ref;
  StreamSubscription? _sessionExpiredSub;
  StreamSubscription? _maintenanceSub;

  SdkStateNotifier(this.ref) : super(null);

  /// Attempt to restore SDK session from secure storage.
  Future<bool> restoreFromStorage() async {
    try {
      final sdk = await HubSightSDK.restoreFromStorage(
        onMaintenance: (m) =>
            ref.read(maintenanceStateProvider.notifier).setMaintenance(m),
        onSessionExpired: () =>
            ref.read(remoteRevocationEventProvider.notifier).trigger(),
      );

      if (sdk != null) {
        _bindSdk(sdk);
        state = sdk;
        // Start lifecycle observer to pause streams in background
        sdk.lifecycle.start();
        return true;
      }
    } catch (e) {
      debugPrint('Failed to restore SDK from storage: $e');
    }
    return false;
  }

  /// Initialize SDK directly from explicit [HubSightAppConfig].
  Future<HubSightSDK> initializeFromConfig(HubSightAppConfig config) async {
    _cleanupCurrent();
    final sdk = await HubSightSDK.initialize(
      config: config,
      onMaintenance: (m) =>
          ref.read(maintenanceStateProvider.notifier).setMaintenance(m),
      onSessionExpired: () =>
          ref.read(remoteRevocationEventProvider.notifier).trigger(),
    );

    _bindSdk(sdk);
    state = sdk;
    sdk.lifecycle.start();
    return sdk;
  }

  /// Zero-Config Enrollment from [.hscfg] container bytes and 6-digit PIN.
  Future<HubSightSDK> enrollFromHscfg({
    required Uint8List fileBytes,
    required String pin6Digits,
  }) async {
    _cleanupCurrent();
    final sdk = await HubSightSDK.fromHscfg(
      fileBytes: fileBytes,
      pin6Digits: pin6Digits,
      onMaintenance: (m) =>
          ref.read(maintenanceStateProvider.notifier).setMaintenance(m),
      onSessionExpired: () =>
          ref.read(remoteRevocationEventProvider.notifier).trigger(),
    );

    _bindSdk(sdk);
    state = sdk;
    sdk.lifecycle.start();
    return sdk;
  }

  void _bindSdk(HubSightSDK sdk) {
    _sessionExpiredSub?.cancel();
    _maintenanceSub?.cancel();

    _sessionExpiredSub = sdk.onSessionExpired.listen((_) {
      ref.read(remoteRevocationEventProvider.notifier).trigger();
    });

    _maintenanceSub = sdk.onMaintenanceMode.listen((m) {
      ref.read(maintenanceStateProvider.notifier).setMaintenance(m);
    });
  }

  void _cleanupCurrent() {
    _sessionExpiredSub?.cancel();
    _maintenanceSub?.cancel();
    state?.dispose();
    state = null;
  }

  @override
  void dispose() {
    _cleanupCurrent();
    super.dispose();
  }
}

/// Central Riverpod provider exposing the [HubSightSDK] instance.
final hubsightSdkProvider =
    StateNotifierProvider<SdkStateNotifier, HubSightSDK?>((ref) {
  return SdkStateNotifier(ref);
});

/// Convenience accessor for [HubSightAuthManager].
final authManagerProvider = Provider<HubSightAuthManager?>((ref) {
  return ref.watch(hubsightSdkProvider)?.auth;
});

/// Convenience accessor for [HubSightCameraService].
final cameraServiceProvider = Provider<HubSightCameraService?>((ref) {
  return ref.watch(hubsightSdkProvider)?.cameras;
});

/// Convenience accessor for [HubSightArchiveService].
final archiveServiceProvider = Provider<HubSightArchiveService?>((ref) {
  return ref.watch(hubsightSdkProvider)?.archive;
});

/// Convenience accessor for [HubSightNotificationService].
final notificationServiceProvider =
    Provider<HubSightNotificationService?>((ref) {
  return ref.watch(hubsightSdkProvider)?.notifications;
});

/// Convenience accessor for [HubSightRelayClient].
final relayClientProvider = Provider<HubSightRelayClient?>((ref) {
  return ref.watch(hubsightSdkProvider)?.relay;
});
