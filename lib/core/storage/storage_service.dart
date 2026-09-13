import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main()');
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(prefs);
});

final appLocaleProvider = StateNotifierProvider<AppLocaleNotifier, Locale>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AppLocaleNotifier(storage);
});

class AppLocaleNotifier extends StateNotifier<Locale> {
  final StorageService _storage;

  AppLocaleNotifier(this._storage)
      : super(Locale(_storage.getLocale() ?? 'vi'));

  Future<void> toggleLocale() async {
    final nextCode = state.languageCode == 'vi' ? 'en' : 'vi';
    state = Locale(nextCode);
    await _storage.setLocale(nextCode);
  }

  Future<void> setLocale(String code) async {
    state = Locale(code);
    await _storage.setLocale(code);
  }
}

/// Manages local user interface preferences like locale.
/// Sensitive credentials and configs are managed securely by HubSightSDK.
class StorageService {
  final SharedPreferences _prefs;
  static const String _keyLocale = 'app_locale';
  static const String _keyThemeMode = 'app_theme_mode';

  StorageService(this._prefs);

  String? getLocale() {
    return _prefs.getString(_keyLocale);
  }

  Future<bool> setLocale(String locale) async {
    return await _prefs.setString(_keyLocale, locale);
  }

  String? getThemeMode() {
    return _prefs.getString(_keyThemeMode);
  }

  Future<bool> setThemeMode(String mode) async {
    return await _prefs.setString(_keyThemeMode, mode);
  }
}
