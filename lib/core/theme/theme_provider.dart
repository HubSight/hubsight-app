import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/sdk_provider.dart';
import '../storage/storage_service.dart';

/// Global provider for managing the app's ThemeMode (system, light, dark).
final appThemeModeProvider = StateNotifierProvider<AppThemeModeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AppThemeModeNotifier(storage, ref);
});

class AppThemeModeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storage;
  final Ref _ref;

  AppThemeModeNotifier(this._storage, this._ref)
      : super(_parseThemeMode(_storage.getThemeMode()));

  static ThemeMode _parseThemeMode(String? val) {
    if (val == 'light') return ThemeMode.light;
    if (val == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  static String modeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final strVal = modeToString(mode);
    await _storage.setThemeMode(strVal);

    // Synchronize asynchronously with backend profile if SDK is connected
    try {
      final sdk = _ref.read(hubsightSdkProvider);
      if (sdk != null) {
        await sdk.auth.updateProfile(theme: strVal);
      }
    } catch (e) {
      debugPrint('Theme sync with backend failed: $e');
    }
  }

  void syncFromProfile(String? profileTheme) {
    if (profileTheme == null || profileTheme.isEmpty) return;
    final mode = _parseThemeMode(profileTheme);
    if (state != mode) {
      state = mode;
      _storage.setThemeMode(modeToString(mode));
    }
  }
}
