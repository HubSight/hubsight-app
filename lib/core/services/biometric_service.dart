import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _keyBiometricEnabled = 'security_biometric_enabled';
  static const String _keyAppLockEnabled = 'security_app_lock_enabled';
  static const String _keyAppPin = 'security_app_pin';
  static const String _keyLockTimeoutMinutes = 'security_lock_timeout_minutes';
  static const String _keyLastBackgroundTimestamp = 'security_last_bg_time';
  static const String _keyLastUsername = 'last_username';
  static const String _keyBioUsername = 'hs_bio_username';
  static const String _keyBioPassword = 'hs_bio_password';

  BiometricService(this._prefs);

  /// Check if hardware supports biometrics
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
      return false;
    }
  }

  bool isAuthenticating = false;

  /// Check if hardware supports biometrics and device has enrolled biometrics
  Future<bool> canAuthenticateWithBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck && !isSupported) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty || canCheck;
    } catch (e) {
      debugPrint('Error checking enrolled biometrics: $e');
      return false;
    }
  }

  /// Get user-friendly label for primary biometric sensor on this device
  Future<String> getBiometricTypeLabel() async {
    try {
      final biometrics = await getAvailableBiometrics();
      if (biometrics.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (biometrics.contains(BiometricType.fingerprint) ||
          biometrics.contains(BiometricType.strong)) {
        return 'Vân tay';
      } else if (biometrics.contains(BiometricType.iris)) {
        return 'Mống mắt';
      }
    } catch (_) {}
    return 'Sinh trắc học';
  }

  /// Get list of available biometric types (Fingerprint, Face, Iris)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Prompt native biometric authentication dialog
  Future<bool> authenticate({
    String localizedReason = 'Vui lòng xác thực để mở khóa HubSight',
  }) async {
    if (isAuthenticating) return false;
    isAuthenticating = true;
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
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        isAuthenticating = false;
      });
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
    if (lastBg == null) return false;

    final elapsedSeconds = (DateTime.now().millisecondsSinceEpoch - lastBg) ~/ 1000;
    final timeoutSeconds = lockTimeoutMinutes * 60;

    return elapsedSeconds >= timeoutSeconds;
  }

  void clearBackgroundTime() {
    _prefs.remove(_keyLastBackgroundTimestamp);
  }

  // --- Biometric Credentials Storage (Keychain / Keystore) ---

  /// Save username and password in secure storage for 1-tap biometric login
  Future<void> saveBiometricCredentials({
    required String username,
    required String password,
  }) async {
    await _secureStorage.write(key: _keyBioUsername, value: username);
    await _secureStorage.write(key: _keyBioPassword, value: password);
    await saveLastUsername(username);
    await setBiometricEnabled(true);
  }

  /// Retrieve stored credentials if biometric is enabled
  Future<Map<String, String>?> getBiometricCredentials() async {
    final u = await _secureStorage.read(key: _keyBioUsername);
    final p = await _secureStorage.read(key: _keyBioPassword);
    if (u != null && u.isNotEmpty && p != null && p.isNotEmpty) {
      return {'username': u, 'password': p};
    }
    return null;
  }

  /// Check whether biometric credentials are saved
  Future<bool> hasBiometricCredentials() async {
    final creds = await getBiometricCredentials();
    return creds != null;
  }

  /// Clear stored credentials
  Future<void> clearBiometricCredentials() async {
    await _secureStorage.delete(key: _keyBioUsername);
    await _secureStorage.delete(key: _keyBioPassword);
    await setBiometricEnabled(false);
  }

  /// Save last used username for form autofill
  Future<void> saveLastUsername(String username) async {
    await _prefs.setString(_keyLastUsername, username);
  }

  /// Retrieve last used username
  String? getLastUsername() {
    return _prefs.getString(_keyLastUsername);
  }
}

