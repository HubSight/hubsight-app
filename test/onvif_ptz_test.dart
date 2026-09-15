import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hubsight_app/l10n/app_localizations.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';
import 'package:hubsight_app/core/services/biometric_service.dart';
import 'package:hubsight_app/core/storage/storage_service.dart';
import 'package:hubsight_app/features/camera/ptz_bottom_sheet.dart';
import 'package:hubsight_app/features/camera/playback_screen.dart';
import 'package:hubsight_app/features/camera/webrtc_viewer.dart';

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
  const testPtzCam = Camera(
    id: 'cam-ptz-1',
    name: 'Front Yard PTZ',
    host: '192.168.1.50',
    isActive: true,
    isStopped: false,
    enableAI: true,
    thumbnailUrl: '',
    streamName: 'front_ptz',
    onvifEnabled: true,
    onvifPtzSupported: true,
  );

  const testOnvifOnlyCam = Camera(
    id: 'cam-onvif-1',
    name: 'Fixed ONVIF Camera',
    host: '192.168.1.51',
    isActive: true,
    isStopped: false,
    enableAI: true,
    thumbnailUrl: '',
    streamName: 'fixed_onvif',
    onvifEnabled: true,
    onvifPtzSupported: false,
  );

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget createWidgetForTesting(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        biometricServiceProvider.overrideWithValue(MockBiometricService(prefs)),
        ...overrides,
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(body: child),
      ),
    );
  }

  group('ONVIF PTZ Bottom Sheet Tests', () {
    testWidgets('renders PTZ controller header, ONVIF badge, and D-pad', (tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          const PtzBottomSheet(camera: testPtzCam),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and camera name
      expect(find.text('Front Yard PTZ'), findsOneWidget);
      expect(find.text('ONVIF Profile S'), findsOneWidget);

      // Check D-Pad widget is present
      expect(find.byKey(const Key('hubsight-ptz-dpad')), findsOneWidget);

      // Check Stop button and Zoom buttons inside HubSightPtzPad
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.text('Zoom +'), findsOneWidget);
      expect(find.text('Zoom -'), findsOneWidget);

      // Check Add Preset button
      expect(find.byKey(const Key('add-preset-button')), findsOneWidget);
    });

    testWidgets('tapping Add Preset opens input dialog', (tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          const PtzBottomSheet(camera: testPtzCam),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-preset-button')));
      await tester.pumpAndSettle();

      // Verify dialog is rendered
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Lưu góc hiện tại'), findsWidgets);
    });
  });

  group('PTZ capability gating', () {
    test('enables controls only for cameras with confirmed PTZ support', () {
      expect(supportsPtzControls(testPtzCam), isTrue);
      expect(supportsPtzControls(testOnvifOnlyCam), isFalse);
      expect(supportsPtzControls(null), isFalse);
    });
  });

  group('WebRTCViewer PTZ Gesture & Button Tests', () {
    testWidgets('renders PTZ action button when hasPtz is true', (tester) async {
      await tester.pumpWidget(
        createWidgetForTesting(
          const WebRTCViewer(
            cameraId: 'cam-ptz-1',
            hasPtz: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('webrtc-ptz-button')), findsOneWidget);
    });
  });
}
