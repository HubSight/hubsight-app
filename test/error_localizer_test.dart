import 'package:cctv_app/core/localization/error_localizer.dart';
import 'package:cctv_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';

void main() {
  group('AppErrorLocalizer Tests', () {
    testWidgets('localizes error codes into Vietnamese and English',
        (tester) async {
      late AppLocalizations viL10n;
      late AppLocalizations enL10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Builder(
            builder: (context) {
              viL10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              enL10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test PIN error
      expect(
        AppErrorLocalizer.localizeCode(
            HubSightErrorCode.configInvalidPinFormat, viL10n),
        contains('6 chữ số'),
      );
      expect(
        AppErrorLocalizer.localizeCode(
            HubSightErrorCode.configInvalidPinFormat, enL10n),
        contains('6 digits'),
      );

      // Test 2FA error
      expect(
        AppErrorLocalizer.localizeCode(
            HubSightErrorCode.authInvalidTwoFactorCode, viL10n),
        isNotEmpty,
      );

      // Test Maintenance error
      expect(
        AppErrorLocalizer.localizeCode(
            HubSightErrorCode.systemMaintenance, viL10n),
        contains('bảo trì'),
      );
      expect(
        AppErrorLocalizer.localizeCode(
            HubSightErrorCode.systemMaintenance, enL10n),
        contains('maintenance'),
      );

      // Test App Key Required & Invalid
      expect(
        AppErrorLocalizer.localizeCode(
            HubSightErrorCode.appKeyRequired, viL10n),
        contains('API Key'),
      );
      expect(
        AppErrorLocalizer.localizeCode(
            HubSightErrorCode.appKeyRequired, enL10n),
        contains('API key'),
      );
      expect(
        AppErrorLocalizer.localizeCode(
            HubSightErrorCode.appKeyInvalidOrRevoked, viL10n),
        contains('thu hồi'),
      );
      expect(
        AppErrorLocalizer.localizeCode(
            HubSightErrorCode.appKeyInvalidOrRevoked, enL10n),
        contains('revoked'),
      );

      // Test generic exception
      final genericStr =
          AppErrorLocalizer.localize(Exception('Unknown network bug'), enL10n);
      expect(genericStr, equals(enL10n.errGeneric));
    });
  });
}
