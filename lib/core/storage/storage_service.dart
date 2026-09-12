import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';

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

class StorageService {
  final SharedPreferences _prefs;
  static const String _keyServerUrl = 'server_url';
  static const String _keyLocale = 'app_locale';
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserProfile = 'user_profile';

  StorageService(this._prefs);

  String? getServerUrl() {
    return _prefs.getString(_keyServerUrl);
  }

  Future<bool> setServerUrl(String url) async {
    // Normalize url: remove trailing slashes
    final normalized = url.trim().replaceAll(RegExp(r'/+$'), '');
    return await _prefs.setString(_keyServerUrl, normalized);
  }

  bool hasServerUrl() {
    final url = getServerUrl();
    return url != null && url.trim().isNotEmpty;
  }

  String? getAuthToken() {
    return _prefs.getString(_keyAuthToken);
  }

  Future<bool> setAuthToken(String token) async {
    return await _prefs.setString(_keyAuthToken, token);
  }

  Future<bool> clearAuthToken() async {
    return await _prefs.remove(_keyAuthToken);
  }

  User? getUserProfile() {
    final str = _prefs.getString(_keyUserProfile);
    if (str == null) return null;
    try {
      return User.fromJson(jsonDecode(str) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> setUserProfile(User user) async {
    return await _prefs.setString(_keyUserProfile, jsonEncode(user.toJson()));
  }

  Future<bool> clearUserProfile() async {
    return await _prefs.remove(_keyUserProfile);
  }

  String? getLocale() {
    return _prefs.getString(_keyLocale);
  }

  Future<bool> setLocale(String locale) async {
    return await _prefs.setString(_keyLocale, locale);
  }
}
