import 'package:cctv_app/features/notifications/notification_screen.dart';
import 'package:cctv_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationScreen Widget Tests', () {
    testWidgets('renders NotificationScreen with dark theme and filter tabs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('vi'),
            home: NotificationScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(NotificationScreen), findsOneWidget);
      expect(find.text('Thông báo'), findsOneWidget);
      expect(find.textContaining('Tất cả'), findsOneWidget);
      expect(find.textContaining('Chưa đọc'), findsOneWidget);
    });
  });
}
