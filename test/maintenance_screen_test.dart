import 'package:cctv_app/core/network/sdk_provider.dart';
import 'package:cctv_app/features/common/maintenance_screen.dart';
import 'package:cctv_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';

void main() {
  group('MaintenanceScreen Widget Tests', () {
    testWidgets('renders maintenance UI and retry button correctly',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            maintenanceStateProvider.overrideWith((ref) =>
                MaintenanceNotifier(const HubSightMaintenanceException(
                    retryAfterSeconds: 45,
                    developerMessage: 'He thong dang bao tri'))),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('vi'),
            home: MaintenanceScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display system maintenance title & countdown
      expect(find.byType(MaintenanceScreen), findsOneWidget);
      expect(find.byIcon(Icons.build_circle_outlined), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
