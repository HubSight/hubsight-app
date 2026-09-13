import 'package:hubsight_app/core/services/biometric_service.dart';
import 'package:hubsight_app/core/storage/storage_service.dart';
import 'package:hubsight_app/features/settings/settings_screen.dart';
import 'package:hubsight_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockBiometricService extends BiometricService {
  MockBiometricService(super.prefs);

  @override
  Future<bool> canAuthenticateWithBiometrics() async => false;

  @override
  Future<bool> canCheckBiometrics() async => false;

  @override
  Future<String> getBiometricTypeLabel() async => 'Vân tay';
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('SettingsScreen Widget Tests', () {
    testWidgets('renders SettingsScreen with flat grouped layout', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            biometricServiceProvider.overrideWithValue(MockBiometricService(prefs)),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('vi'),
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Cài đặt'), findsOneWidget);
      expect(find.text('NGÔN NGỮ'), findsOneWidget);
      expect(find.text('GIAO DIỆN HIỂN THỊ'), findsOneWidget);
      expect(find.text('Theo thiết bị'), findsOneWidget);
      expect(find.text('Sáng'), findsOneWidget);
      expect(find.text('Tối'), findsOneWidget);
      expect(find.text('KHÓA BẢO MẬT & SINH TRẮC HỌC'), findsOneWidget);
      expect(find.text('Thêm thiết bị'), findsOneWidget);
      expect(find.text('BẢO MẬT ỨNG DỤNG'), findsOneWidget);
      expect(find.text('CÀI ĐẶT THÔNG BÁO ĐẨY (PUSH)'), findsOneWidget);
      expect(find.text('CẤU HÌNH MÁY CHỦ'), findsOneWidget);
    });

    testWidgets('allows switching theme mode via pill buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            biometricServiceProvider.overrideWithValue(MockBiometricService(prefs)),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('vi'),
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap on 'Sáng' (Light)
      await tester.tap(find.text('Sáng'));
      await tester.pumpAndSettle();

      // Verify preference saved in StorageService
      expect(prefs.getString('app_theme_mode'), 'light');

      // Tap on 'Tối' (Dark)
      await tester.tap(find.text('Tối'));
      await tester.pumpAndSettle();
      expect(prefs.getString('app_theme_mode'), 'dark');

      // Tap on 'Theo thiết bị' (System)
      await tester.tap(find.text('Theo thiết bị'));
      await tester.pumpAndSettle();
      expect(prefs.getString('app_theme_mode'), 'system');
    });
  });
}
