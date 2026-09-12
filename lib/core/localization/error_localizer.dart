import 'package:cctv_app/l10n/app_localizations.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';

/// Resolves machine-readable [HubSightErrorCode] or [Exception] into localized user-facing UI messages.
class AppErrorLocalizer {
  /// Localize any error or exception using current context's [AppLocalizations].
  static String localize(Object error, AppLocalizations l10n) {
    if (error is HubSightException) {
      return localizeCode(error.code, l10n);
    }
    return l10n.errGeneric;
  }

  /// Localize a specific [HubSightErrorCode].
  static String localizeCode(HubSightErrorCode code, AppLocalizations l10n) {
    switch (code) {
      case HubSightErrorCode.configInvalidPinFormat:
        return l10n.errConfigInvalidPin;
      case HubSightErrorCode.configDecryptionFailed:
      case HubSightErrorCode.configCorrupted:
      case HubSightErrorCode.configInvalidHeader:
      case HubSightErrorCode.configDecompressionFailed:
      case HubSightErrorCode.configMissingRequiredFiles:
      case HubSightErrorCode.configMalformedYaml:
        return l10n.errConfigDecryptionFailed;
      case HubSightErrorCode.configInvalidSignature:
        return l10n.errConfigInvalidSignature;

      case HubSightErrorCode.authInvalidCredentials:
        return l10n.errAuthInvalidCredentials;
      case HubSightErrorCode.authTwoFactorRequired:
      case HubSightErrorCode.authInvalidTwoFactorCode:
        return l10n.twoFactorFailed;
      case HubSightErrorCode.authRefreshTokenExpired:
      case HubSightErrorCode.authRefreshTokenRevoked:
        return l10n.errSessionExpired;

      case HubSightErrorCode.networkTimeout:
        return l10n.errNetworkTimeout;
      case HubSightErrorCode.networkUnreachable:
      case HubSightErrorCode.networkConnectionRefused:
        return l10n.errNetworkUnreachable;

      case HubSightErrorCode.systemMaintenance:
        return l10n.maintenanceMessage;

      case HubSightErrorCode.appKeyRequired:
        return l10n.errAppKeyRequired;
      case HubSightErrorCode.appKeyInvalidOrRevoked:
        return l10n.errAppKeyInvalid;

      default:
        return l10n.errGeneric;
    }
  }
}
