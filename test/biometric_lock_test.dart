import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hubsight_app/core/services/biometric_service.dart';
import 'package:hubsight_app/core/storage/storage_service.dart';
import 'package:hubsight_app/features/auth/app_lock_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFaceIdBiometricService extends BiometricService {
  MockFaceIdBiometricService(super.prefs);

  @override
  Future<bool> canAuthenticateWithBiometrics() async => true;

  @override
  Future<bool> canCheckBiometrics() async => true;

  @override
  Future<String> getBiometricTypeLabel() async => 'Face ID';

  @override
  Future<bool> authenticate({String localizedReason = ''}) async => true;
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('BiometricService Timeout & Lifecycle Tests', () {
    test('shouldRequireUnlock returns false if app lock is disabled', () {
      final bio = BiometricService(prefs);
      bio.recordBackgroundTime();
      expect(bio.shouldRequireUnlock(), isFalse);
    });

    test('shouldRequireUnlock returns false when app was never backgrounded (lastBg is null)', () async {
      final bio = BiometricService(prefs);
      await bio.setAppLockEnabled(true);
      await bio.setLockTimeoutMinutes(0); // Immediate
      // Without recordBackgroundTime(), lastBg is null
      expect(bio.shouldRequireUnlock(), isFalse);
    });

    test('shouldRequireUnlock returns true when immediate timeout passed', () async {
      final bio = BiometricService(prefs);
      await bio.setAppLockEnabled(true);
      await bio.setLockTimeoutMinutes(0); // Immediate
      bio.recordBackgroundTime();
      expect(bio.shouldRequireUnlock(), isTrue);
    });

    test('shouldRequireUnlock respects timeout minutes and clearBackgroundTime', () async {
      final bio = BiometricService(prefs);
      await bio.setAppLockEnabled(true);
      await bio.setLockTimeoutMinutes(5);

      // Recorded 1 minute ago (not yet 5 minutes)
      prefs.setInt(
        'security_last_bg_time',
        DateTime.now().subtract(const Duration(minutes: 1)).millisecondsSinceEpoch,
      );
      expect(bio.shouldRequireUnlock(), isFalse);

      // Recorded 6 minutes ago (exceeded 5 minutes)
      prefs.setInt(
        'security_last_bg_time',
        DateTime.now().subtract(const Duration(minutes: 6)).millisecondsSinceEpoch,
      );
      expect(bio.shouldRequireUnlock(), isTrue);

      // Unlocked -> clearBackgroundTime()
      bio.clearBackgroundTime();
      expect(bio.shouldRequireUnlock(), isFalse);
    });
  });

  group('AppLockScreen Widget Tests', () {
    testWidgets('renders PIN indicator dots and Face ID icon for Face ID devices', (tester) async {
      final mockBio = MockFaceIdBiometricService(prefs);
      await mockBio.setAppLockEnabled(true);
      await mockBio.savePin('1234');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            biometricServiceProvider.overrideWithValue(mockBio),
          ],
          child: MaterialApp(
            home: AppLockScreen(
              onUnlocked: () {},
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Keypad digits should be visible
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      // Face ID icon should be present on keypad
      expect(find.byIcon(Icons.face_rounded), findsOneWidget);
    });
  });
}
