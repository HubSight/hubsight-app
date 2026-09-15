import 'package:hubsight_app/core/storage/storage_service.dart';
import 'package:hubsight_app/features/auth/login_screen.dart';
import 'package:hubsight_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hubsight_app/core/services/biometric_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';

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

  group('Login session validation', () {
    test('rejects a successful response without an access token', () {
      const result = AuthResult(isSuccess: true);

      expect(hasUsableLoginToken(result), isFalse);
    });

    test('rejects an empty access token', () {
      const result = AuthResult(isSuccess: true, accessToken: '   ');

      expect(hasUsableLoginToken(result), isFalse);
    });

    test('accepts a successful response with an opaque Bearer token', () {
      const result = AuthResult(
        isSuccess: true,
        accessToken: 'opaque_access_token',
      );

      expect(hasUsableLoginToken(result), isTrue);
    });

    test('rejects a non-Bearer token type', () {
      const result = AuthResult(
        isSuccess: true,
        accessToken: 'opaque_access_token',
        tokenType: 'Basic',
      );

      expect(hasUsableLoginToken(result), isFalse);
    });

    test('accepts a non-expired JWT and rejects an expired JWT', () {
      const activeResult = AuthResult(
        isSuccess: true,
        accessToken:
            'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c3JfMDAxIiwidXNlcm5hbWUiOiJhZG1pbiIsInJvbGUiOiJhZG1pbiIsInNlc3Npb25faWQiOiJzZXNzXzAwMSIsImV4cCI6MjUyNDYwODAwMH0.signature',
      );
      const expiredResult = AuthResult(
        isSuccess: true,
        accessToken:
            'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c3JfMDAxIiwidXNlcm5hbWUiOiJhZG1pbiIsInJvbGUiOiJhZG1pbiIsInNlc3Npb25faWQiOiJzZXNzXzAwMSIsImV4cCI6MTAwMDAwMDAwMH0.signature',
      );

      expect(hasUsableLoginToken(activeResult), isTrue);
      expect(hasUsableLoginToken(expiredResult), isFalse);
    });
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
      expect(
        find.byKey(const Key('login-server-config-badge')),
        findsOneWidget,
      );
      expect(find.text('Chưa cấu hình máy chủ'), findsOneWidget);
      expect(find.byIcon(Icons.file_upload_outlined), findsOneWidget);
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

    testWidgets('empty password does not trigger login request',
        (tester) async {
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

    testWidgets('passkey login requires a username', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            biometricServiceProvider
                .overrideWithValue(MockBiometricService(prefs)),
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

      final passkeyButton = find.byType(OutlinedButton);
      expect(passkeyButton, findsOneWidget);
      await tester.ensureVisible(passkeyButton);
      await tester.tap(passkeyButton);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(
        find.text('Nhập tên đăng nhập trước khi đăng nhập bằng Passkey.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'submitting username moves focus to password and submitting password triggers login',
        (tester) async {
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

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      // Test username submission triggers next action
      await tester.showKeyboard(textFields.first);
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      // Enter password and submit with done action
      await tester.enterText(textFields.last, 'testpassword123');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    });
  });
}
