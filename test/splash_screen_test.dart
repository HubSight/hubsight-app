import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hubsight_app/core/services/biometric_service.dart';
import 'package:hubsight_app/core/services/fcm_service.dart';
import 'package:hubsight_app/core/storage/storage_service.dart';
import 'package:hubsight_app/features/auth/login_screen.dart';
import 'package:hubsight_app/features/common/splash_screen.dart';
import 'package:hubsight_app/l10n/app_localizations.dart';
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

class MockFcmService extends FcmService {
  MockFcmService({required super.ref});

  @override
  Future<void> initialize() async {}
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('SplashScreen Widget Tests', () {
    testWidgets('renders branded logo, title, and tagline', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            biometricServiceProvider.overrideWithValue(MockBiometricService(prefs)),
            fcmServiceProvider.overrideWith((ref) => MockFcmService(ref: ref)),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('vi'),
            home: SplashScreen(
              minDisplayDuration: Duration(seconds: 10), // keep on screen during test
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Brand Title
      expect(find.text('HubSight'), findsOneWidget);

      // Official HubSight brand mark
      expect(find.byKey(const Key('hubsight-brand-mark')), findsOneWidget);

      // Vietnamese Tagline & Subtitle
      expect(find.text('Giám sát & Quản trị Camera Thông minh'), findsOneWidget);
      expect(find.text('Nền tảng Camera An ninh & AI Doanh nghiệp'), findsOneWidget);

      // Drain timer
      await tester.pumpAndSettle(const Duration(seconds: 10));
    });

    testWidgets('unauthenticated launch navigates to LoginScreen smoothly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            biometricServiceProvider.overrideWithValue(MockBiometricService(prefs)),
            fcmServiceProvider.overrideWith((ref) => MockFcmService(ref: ref)),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('vi'),
            home: SplashScreen(
              minDisplayDuration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Initially on Splash
      await tester.pump();
      expect(find.text('HubSight'), findsOneWidget);

      // Advance time beyond minDisplayDuration
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Should have transitioned to LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Đăng nhập'), findsOneWidget);
    });
  });
}
