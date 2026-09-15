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

/// Returns true only when the SDK uses an imported server profile.
///
/// Older app versions persisted a built-in `default_config`; treating that
/// fallback as provisioned would incorrectly allow users to reach Login.
bool hasImportedHubSightConfig(HubSightSDK? sdk) {
  if (sdk == null) return false;
  final config = sdk.config;
  final isLegacyDefault = config.metadata.configId == 'default_config' &&
      config.key.clientId == 'hs_mob_default';
  return !isLegacyDefault;
}

/// Validates the stored SDK session and proactively refreshes expired JWTs.
///
/// Older deployments may still issue opaque access tokens. When claims cannot
/// be decoded, the SDK's authenticated state and 401 interceptor remain the
/// source of truth for backward compatibility.
Future<bool> ensureUsableHubSightSession(HubSightSDK sdk) async {
  if (!await sdk.auth.isAuthenticated) return false;

  final claims = await sdk.auth.getClaims();
  if (claims == null || !claims.isExpired) return true;

  try {
    if (!await sdk.auth.refreshToken()) return false;
    final refreshedClaims = await sdk.auth.getClaims();
    return refreshedClaims == null || !refreshedClaims.isExpired;
  } catch (_) {
    return false;
  }
}

/// Central Riverpod provider exposing the [HubSightSDK] instance.
final hubsightSdkProvider =
    StateNotifierProvider<SdkStateNotifier, HubSightSDK?>((ref) {
  return SdkStateNotifier(ref);
});
