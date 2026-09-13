import 'package:hubsight_app/core/storage/storage_service.dart';
import 'package:hubsight_app/features/auth/login_screen.dart';
import 'package:hubsight_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hubsight_app/core/services/biometric_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  group('LoginScreen Widget Tests', () {
    testWidgets('renders login form elements correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('vi'),
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and branding
      expect(find.text('HubSight'), findsOneWidget);
      expect(find.text('TÊN ĐĂNG NHẬP'), findsOneWidget);
      expect(find.text('MẬT KHẨU'), findsOneWidget);

      // Check username field exists (value + hint)
      expect(find.text('admin'), findsAtLeastNWidgets(1));

      // Check login button
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Check OR divider and Biometric / Passkey button
      expect(find.text('HOẶC'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byIcon(Icons.fingerprint_rounded), findsOneWidget);
    });

    testWidgets('empty password does not trigger login request', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('vi'),
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap login without entering password
      await tester.tap(find.text('Đăng nhập'));
      await tester.pump();

      // No error banner should be shown because validation blocked empty input
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('tapping biometric button without credentials prompts guidance', (tester) async {
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
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the biometric button
      final bioBtn = find.byType(OutlinedButton);
      expect(bioBtn, findsOneWidget);
      await tester.ensureVisible(bioBtn);
      await tester.tap(bioBtn);
      await tester.pumpAndSettle();

      // Error banner indicates biometrics not supported on device
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Thiết bị không hỗ trợ hoặc chưa cài đặt sinh trắc học.'), findsOneWidget);
    });
  });
}
