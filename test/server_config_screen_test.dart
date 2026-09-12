import 'package:cctv_app/core/network/sdk_provider.dart';
import 'package:cctv_app/features/config/server_config_screen.dart';
import 'package:cctv_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServerConfigScreen Widget Tests', () {
    testWidgets('renders dual-tab configuration UI', (tester) async {
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

      // Should have 2 tabs: Auto (.hscfg) and Manual
      expect(find.byType(Tab), findsNWidgets(2));
    });
  });
}
