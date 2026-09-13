import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hubsight_app/core/services/biometric_service.dart';
import 'package:hubsight_app/core/storage/storage_service.dart';
import 'package:hubsight_app/features/camera/playback_screen.dart';
import 'package:hubsight_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockBiometricService extends BiometricService {
  MockBiometricService(super.prefs);

  @override
  Future<bool> canAuthenticateWithBiometrics() async => false;

  @override
  Future<bool> canCheckBiometrics() async => false;

  @override
  Future<String> getBiometricTypeLabel() async => 'Face ID';
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildPlaybackScreenHost() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        biometricServiceProvider.overrideWithValue(MockBiometricService(prefs)),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('vi'),
        home: PlaybackScreen(),
      ),
    );
  }

  group('PlaybackScreen Unified Layout Tests', () {
    testWidgets('renders 16:9 player, quick camera bar, 24h timeline and activity section', (tester) async {
      await tester.pumpWidget(buildPlaybackScreenHost());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Header HubSight
      expect(find.text('HubSight'), findsOneWidget);

      // Unified 24h Timeline labels
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('06:00'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
      expect(find.text('18:00'), findsOneWidget);
      expect(find.text('24:00'), findsOneWidget);

      // Live mode toggle
      expect(find.text('Live'), findsOneWidget);

      // Activity section
      expect(find.text('Nhật ký nhận diện gần đây'), findsOneWidget);
    });

    testWidgets('renders PlaybackScreen in dark theme with zero overflow and proper contrast', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            biometricServiceProvider.overrideWithValue(MockBiometricService(prefs)),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            themeMode: ThemeMode.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            home: const PlaybackScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('HubSight'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('24:00'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('toggles fullscreen mode with standard icon and controls', (tester) async {
      await tester.pumpWidget(buildPlaybackScreenHost());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Locate standard fullscreen button in player controls
      final fsButton = find.byKey(const ValueKey('webrtc-fullscreen-button'));
      expect(fsButton, findsOneWidget);
      expect(find.byIcon(Icons.fullscreen_rounded), findsWidgets);

      // Tap to enter fullscreen
      await tester.tap(fsButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // HubSight title in AppBar should now be hidden in fullscreen mode
      expect(find.text('HubSight'), findsNothing);

      // Standard exit fullscreen icon and back button should be visible
      expect(find.byIcon(Icons.fullscreen_exit_rounded), findsWidgets);
      expect(find.byKey(const ValueKey('fullscreen-back-button')), findsOneWidget);

      // Tap exit fullscreen
      await tester.tap(find.byKey(const ValueKey('fullscreen-back-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Should return to normal layout
      expect(find.text('HubSight'), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen_rounded), findsWidgets);
    });

    testWidgets('toggles fullscreen mode in archive playback player', (tester) async {
      await tester.pumpWidget(buildPlaybackScreenHost());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap date selector to switch to archive mode
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Confirm date picker dialog (tap OK)
      await tester.tap(find.text('OK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Archive player should now be visible with its fullscreen button
      final archiveFsButton = find.byKey(const ValueKey('archive-fullscreen-button'));
      expect(archiveFsButton, findsOneWidget);

      // Tap archive fullscreen button
      await tester.tap(archiveFsButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // App bar should be hidden and archive fullscreen back button visible
      expect(find.text('HubSight'), findsNothing);
      expect(find.byKey(const ValueKey('archive-fullscreen-back-button')), findsOneWidget);

      // Tap back button to exit fullscreen
      await tester.tap(find.byKey(const ValueKey('archive-fullscreen-back-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Back in normal layout
      expect(find.text('HubSight'), findsOneWidget);
    });
  });
}
