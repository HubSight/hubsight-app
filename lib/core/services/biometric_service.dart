import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/storage_service.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BiometricService(prefs);
});

class BiometricService {
  final SharedPreferences _prefs;
  final LocalAuthentication _auth = LocalAuthentication();

  static const String _keyBiometricEnabled = 'security_biometric_enabled';
  static const String _keyAppLockEnabled = 'security_app_lock_enabled';
  static const String _keyAppPin = 'security_app_pin';
  static const String _keyLockTimeoutMinutes = 'security_lock_timeout_minutes';
  static const String _keyLastBackgroundTimestamp = 'security_last_bg_time';

  BiometricService(this._prefs);

  /// Check if hardware supports biometrics
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (e) {
      debugPrint('Error checking biometrics: $e');
      return false;
    }
  }

  /// Get list of available biometric types (Fingerprint, Face, Iris)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Prompt native biometric authentication dialog
  Future<bool> authenticate({
    String localizedReason = 'Vui lòng xác thực để mở khóa HubSight CCTV',
  }) async {
    try {
      final isSupported = await canCheckBiometrics();
      if (!isSupported) return false;

      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  // --- Preferences Getters & Setters ---

  bool get isBiometricEnabled => _prefs.getBool(_keyBiometricEnabled) ?? false;
  Future<void> setBiometricEnabled(bool value) async {
    await _prefs.setBool(_keyBiometricEnabled, value);
  }

  bool get isAppLockEnabled => _prefs.getBool(_keyAppLockEnabled) ?? false;
  Future<void> setAppLockEnabled(bool value) async {
    await _prefs.setBool(_keyAppLockEnabled, value);
  }

  int get lockTimeoutMinutes => _prefs.getInt(_keyLockTimeoutMinutes) ?? 0;
  Future<void> setLockTimeoutMinutes(int minutes) async {
    await _prefs.setInt(_keyLockTimeoutMinutes, minutes);
  }

  String? get savedPin => _prefs.getString(_keyAppPin);
  bool get hasPin => savedPin != null && savedPin!.isNotEmpty;

  Future<void> savePin(String pin) async {
    await _prefs.setString(_keyAppPin, pin);
    await setAppLockEnabled(true);
  }

  Future<void> removePin() async {
    await _prefs.remove(_keyAppPin);
    await setAppLockEnabled(false);
    await setBiometricEnabled(false);
  }

  bool verifyPin(String pin) {
    final saved = savedPin;
    if (saved == null) return false;
    return saved == pin;
  }

  // --- Background / Inactivity Timeout Tracking ---

  void recordBackgroundTime() {
    _prefs.setInt(_keyLastBackgroundTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  bool shouldRequireUnlock() {
    if (!isAppLockEnabled) return false;

    final lastBg = _prefs.getInt(_keyLastBackgroundTimestamp);
    if (lastBg == null) return true;

    final elapsedSeconds = (DateTime.now().millisecondsSinceEpoch - lastBg) ~/ 1000;
    final timeoutSeconds = lockTimeoutMinutes * 60;

    return elapsedSeconds >= timeoutSeconds;
  }

  void clearBackgroundTime() {
    _prefs.remove(_keyLastBackgroundTimestamp);
  }
}

