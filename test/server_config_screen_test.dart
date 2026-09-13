import 'package:hubsight_app/features/config/server_config_screen.dart';
import 'package:hubsight_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServerConfigScreen Widget Tests', () {
    testWidgets('renders dual-tab configuration UI with QR and File tabs', (tester) async {
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

      // Screen should render with TabBar
      expect(find.byType(ServerConfigScreen), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);

      // Should have 2 tabs: Quét mã QR & Tệp cấu hình (.hscfg)
      expect(find.byType(Tab), findsNWidgets(2));
      expect(find.text('Quét mã QR'), findsOneWidget);
      expect(find.text('Tệp cấu hình (.hscfg)'), findsOneWidget);

      // Tab 1 (QR Scanner) should show pick image button
      expect(find.text('Chọn ảnh QR từ thư viện'), findsOneWidget);

      // Switch to Tab 2 (File Picker)
      await tester.tap(find.text('Tệp cấu hình (.hscfg)'));
      await tester.pumpAndSettle();

      // Tab 2 should show file picker elements
      expect(find.text('Chọn tệp .hscfg'), findsOneWidget);
      expect(find.text('MÃ PIN BẢO MẬT (6 SỐ)'), findsOneWidget);
      expect(find.text('Giải mã & Kết nối'), findsOneWidget);
    });
  });
}
