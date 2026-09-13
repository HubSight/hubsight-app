import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hubsight_app/core/services/biometric_service.dart';
import 'package:hubsight_app/core/storage/storage_service.dart';
import 'package:hubsight_app/features/camera/playback_screen.dart';
import 'package:hubsight_app/features/common/main_tab_screen.dart';
import 'package:hubsight_app/features/dashboard/dashboard_screen.dart';
import 'package:hubsight_app/features/notifications/notification_screen.dart';
import 'package:hubsight_app/features/settings/settings_screen.dart';
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

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildTabScreenHost({int initialTab = 0, Locale locale = const Locale('vi')}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        biometricServiceProvider.overrideWithValue(MockBiometricService(prefs)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: MainTabScreen(initialTab: initialTab),
      ),
    );
  }

  group('MainTabScreen Widget Tests', () {
    testWidgets('renders all 4 tabs with proper labels and icons', (tester) async {
      await tester.pumpWidget(buildTabScreenHost());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Xem lại'), findsWidgets);
      expect(find.text('Lưới Camera'), findsWidgets);
      expect(find.text('Thông báo'), findsWidgets);
      expect(find.text('Cài đặt'), findsWidgets);

      // Tab 0 (PlaybackScreen) is visible initially
      expect(find.byType(PlaybackScreen), findsOneWidget);
    });

    testWidgets('switching tabs via bottom bar updates IndexedStack view', (tester) async {
      await tester.pumpWidget(buildTabScreenHost());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Lưới Camera tab
      await tester.tap(find.text('Lưới Camera'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(DashboardScreen), findsOneWidget);

      // Tap Thông báo tab
      await tester.tap(find.text('Thông báo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(NotificationScreen), findsOneWidget);

      // Tap Cài đặt tab
      await tester.tap(find.text('Cài đặt'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Ngôn ngữ'), findsOneWidget);
      expect(find.text('Tiếng Việt'), findsWidgets);
    });

    testWidgets('badge displays unread count on Notifications tab', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            biometricServiceProvider.overrideWithValue(MockBiometricService(prefs)),
            unreadNotificationCountProvider.overrideWith((ref) => 5),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('vi'),
            home: MainTabScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('5'), findsOneWidget);
    });
  });
}
