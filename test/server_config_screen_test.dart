import 'dart:typed_data';
import 'package:hubsight_app/core/theme/app_theme.dart';
import 'package:hubsight_app/features/config/server_config_screen.dart';
import 'package:hubsight_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServerConfigScreen Wizard Tests', () {
    testWidgets('navigates through wizard steps from Welcome to Method and File/QR selection', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('vi'),
            home: ServerConfigScreen(isInitialSetup: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Welcome Step
      expect(find.byType(ServerConfigScreen), findsOneWidget);
      expect(find.text('Chào mừng đến với HubSight'), findsOneWidget);
      expect(find.text('Bắt đầu thiết lập'), findsOneWidget);

      // Advance to Step 2: Select Method
      await tester.ensureVisible(find.text('Bắt đầu thiết lập'));
      await tester.tap(find.text('Bắt đầu thiết lập'));
      await tester.pumpAndSettle();

      expect(find.text('Chọn phương thức kết nối'), findsOneWidget);
      expect(find.text('Quét mã QR cấu hình'), findsOneWidget);
      expect(find.text('Chọn tệp cấu hình (.hscfg)'), findsOneWidget);

      // Select Option 2: Import File (Step 3a)
      await tester.tap(find.text('Chọn tệp cấu hình (.hscfg)'));
      await tester.pumpAndSettle();

      expect(find.text('Nhấn để chọn tệp .hscfg'), findsOneWidget);
      expect(find.text('Quay lại'), findsOneWidget);

      // Tap Back -> Returns to Step 2
      await tester.tap(find.text('Quay lại'));
      await tester.pumpAndSettle();

      expect(find.text('Chọn phương thức kết nối'), findsOneWidget);

      // Select Option 1: Scan QR (Step 3b)
      await tester.tap(find.text('Quét mã QR cấu hình'));
      await tester.pumpAndSettle();

      expect(find.text('Chọn ảnh QR từ thư viện'), findsOneWidget);
    });

    testWidgets('renders Step 4 PIN entry with 6 discrete cells and validates input', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('vi'),
            home: ServerConfigScreen(
              isInitialSetup: true,
              initialStep: ConfigWizardStep.enterPin,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nhập mã PIN bảo mật (6 số)'), findsOneWidget);
      expect(find.byKey(const Key('config-pin-input-field')), findsOneWidget);
      expect(find.text('Giải nén & Giải mã'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('config-pin-input-field')), '123456');
      await tester.pumpAndSettle();

      // Tap Giải nén & Giải mã without file -> shows error
      await tester.tap(find.text('Giải nén & Giải mã'));
      await tester.pumpAndSettle();

      expect(find.text('Chưa có tệp tin cấu hình. Vui lòng quay lại bước trước.'), findsOneWidget);
    });

    testWidgets('renders Step 3a with imported file and styled "Chọn tệp khác" button under Light and Dark mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            home: ServerConfigScreen(
              isInitialSetup: true,
              initialStep: ConfigWizardStep.pickFile,
              initialConfigBytes: Uint8List.fromList([1, 2, 3, 4, 5]),
              initialConfigFileName: 'cctv.quoctran.space.hscfg',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Chọn tệp cấu hình (.hscfg)'), findsOneWidget);
      expect(find.text('cctv.quoctran.space.hscfg'), findsOneWidget);
      expect(find.text('SẴN SÀNG GIẢI MÃ'), findsOneWidget);
      expect(find.text('Chọn tệp khác'), findsOneWidget);

      final outlinedButtonFinder = find.widgetWithText(OutlinedButton, 'Chọn tệp khác');
      expect(outlinedButtonFinder, findsOneWidget);

      final buttonWidget = tester.widget<OutlinedButton>(outlinedButtonFinder);
      final style = buttonWidget.style;
      expect(style, isNotNull);
      expect(style?.foregroundColor?.resolve({}), Colors.white);
      expect(style?.backgroundColor?.resolve({}), Colors.white.withValues(alpha: 0.08));
    });
  });
}
