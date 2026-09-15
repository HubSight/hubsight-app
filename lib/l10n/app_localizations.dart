import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HubSight'**
  String get appTitle;

  /// No description provided for @languageSelector.
  ///
  /// In en, this message translates to:
  /// **'EN English'**
  String get languageSelector;

  /// No description provided for @languageBadge.
  ///
  /// In en, this message translates to:
  /// **'EN EN'**
  String get languageBadge;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login to manage devices and review'**
  String get loginSubtitle;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'USERNAME'**
  String get usernameLabel;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'admin'**
  String get usernameHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••••••'**
  String get passwordHint;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @footerVersion.
  ///
  /// In en, this message translates to:
  /// **'HubSight v1.0.0+sha-91d8e0d.'**
  String get footerVersion;

  /// No description provided for @footerCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 by Anh Quoc Tran'**
  String get footerCopyright;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'HubSight Live Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardNoCameras.
  ///
  /// In en, this message translates to:
  /// **'No cameras found'**
  String get dashboardNoCameras;

  /// No description provided for @cameraOffline.
  ///
  /// In en, this message translates to:
  /// **'Camera Offline'**
  String get cameraOffline;

  /// No description provided for @cameraOnline.
  ///
  /// In en, this message translates to:
  /// **'Active (Online)'**
  String get cameraOnline;

  /// No description provided for @cameraStopped.
  ///
  /// In en, this message translates to:
  /// **'Offline / Stopped'**
  String get cameraStopped;

  /// No description provided for @selectCamera.
  ///
  /// In en, this message translates to:
  /// **'Select camera'**
  String get selectCamera;

  /// No description provided for @deviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Device:'**
  String get deviceLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date:'**
  String get dateLabel;

  /// No description provided for @recordsLabel.
  ///
  /// In en, this message translates to:
  /// **'Recordings:'**
  String get recordsLabel;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @recordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} recordings'**
  String recordsCount(Object count);

  /// No description provided for @eventTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Timeline (Event-based Playback)'**
  String get eventTimelineTitle;

  /// No description provided for @noEventsToday.
  ///
  /// In en, this message translates to:
  /// **'No unusual events recorded on this day'**
  String get noEventsToday;

  /// No description provided for @eventsToday.
  ///
  /// In en, this message translates to:
  /// **'{count} events recorded'**
  String eventsToday(Object count);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String filterAll(Object count);

  /// No description provided for @filterMorning.
  ///
  /// In en, this message translates to:
  /// **'00-12h'**
  String get filterMorning;

  /// No description provided for @filterAfternoon.
  ///
  /// In en, this message translates to:
  /// **'12-18h'**
  String get filterAfternoon;

  /// No description provided for @filterEvening.
  ///
  /// In en, this message translates to:
  /// **'18-24h'**
  String get filterEvening;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;

  /// No description provided for @cameraStoppedStatus.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get cameraStoppedStatus;

  /// No description provided for @cameraStoppedTitle.
  ///
  /// In en, this message translates to:
  /// **'“{camera}” is offline'**
  String cameraStoppedTitle(Object camera);

  /// No description provided for @cameraStoppedDesc.
  ///
  /// In en, this message translates to:
  /// **'Live stream is offline. Choose another camera from the list, or wait for admin to restart it.'**
  String get cameraStoppedDesc;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationTitle;

  /// No description provided for @notificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Person recognition history & security alerts'**
  String get notificationSubtitle;

  /// No description provided for @filterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread ({count})'**
  String filterUnread(Object count);

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @viewPlayback.
  ///
  /// In en, this message translates to:
  /// **'Watch camera'**
  String get viewPlayback;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @confirmDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all notifications?'**
  String get confirmDeleteAll;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get confirmDelete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @menuHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get menuHome;

  /// No description provided for @menuDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get menuDevices;

  /// No description provided for @menuMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get menuMembers;

  /// No description provided for @menuPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get menuPlayback;

  /// No description provided for @tabPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get tabPlayback;

  /// No description provided for @tabDashboard.
  ///
  /// In en, this message translates to:
  /// **'Live Grid'**
  String get tabDashboard;

  /// No description provided for @tabNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get tabNotifications;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @menuNvrMonitor.
  ///
  /// In en, this message translates to:
  /// **'NVR Monitor'**
  String get menuNvrMonitor;

  /// No description provided for @menuConnectionPool.
  ///
  /// In en, this message translates to:
  /// **'Connection Pool'**
  String get menuConnectionPool;

  /// No description provided for @menuLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get menuLanguage;

  /// No description provided for @sidebarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live Surveillance'**
  String get sidebarSubtitle;

  /// No description provided for @adminRole.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get adminRole;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Device & Security Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize notifications, timezone and app lock security'**
  String get settingsSubtitle;

  /// No description provided for @appModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Web Browser Mode'**
  String get appModeTitle;

  /// No description provided for @appModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Install the app as a standalone application for the smoothest lock experience.'**
  String get appModeDesc;

  /// No description provided for @timezoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Display Timezone'**
  String get timezoneTitle;

  /// No description provided for @timezoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Timezone used to display time in notifications and logs (Default: UTC+7).'**
  String get timezoneDesc;

  /// No description provided for @selectTimezone.
  ///
  /// In en, this message translates to:
  /// **'Select timezone'**
  String get selectTimezone;

  /// No description provided for @pushSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Push Notification Settings'**
  String get pushSettingsTitle;

  /// No description provided for @pushSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose event categories for push notifications'**
  String get pushSettingsSubtitle;

  /// No description provided for @pushFamily.
  ///
  /// In en, this message translates to:
  /// **'Familiar Persons (Family, Guests)'**
  String get pushFamily;

  /// No description provided for @pushFamilyDesc.
  ///
  /// In en, this message translates to:
  /// **'Notify when camera recognizes family members or regular guests.'**
  String get pushFamilyDesc;

  /// No description provided for @pushStranger.
  ///
  /// In en, this message translates to:
  /// **'Security Alerts & Strangers'**
  String get pushStranger;

  /// No description provided for @pushStrangerDesc.
  ///
  /// In en, this message translates to:
  /// **'Includes strangers, intrusions, falls, weapons, fire/smoke...'**
  String get pushStrangerDesc;

  /// No description provided for @pushSystem.
  ///
  /// In en, this message translates to:
  /// **'System Notifications'**
  String get pushSystem;

  /// No description provided for @pushSystemDesc.
  ///
  /// In en, this message translates to:
  /// **'Alerts on NVR system status, connection errors or full storage.'**
  String get pushSystemDesc;

  /// No description provided for @lockOnBackground.
  ///
  /// In en, this message translates to:
  /// **'Lock on Background'**
  String get lockOnBackground;

  /// No description provided for @lockOnBackgroundDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically lock screen when app is hidden or minimized.'**
  String get lockOnBackgroundDesc;

  /// No description provided for @biometricUnlock.
  ///
  /// In en, this message translates to:
  /// **'Biometric Unlock (Face ID / Fingerprint)'**
  String get biometricUnlock;

  /// No description provided for @biometricUnlockDesc.
  ///
  /// In en, this message translates to:
  /// **'Use WebAuthn biometric sensors or device PIN for quick unlock.'**
  String get biometricUnlockDesc;

  /// No description provided for @lockTimeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Screen Lock Timeout'**
  String get lockTimeoutTitle;

  /// No description provided for @lockTimeoutDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose how long the app stays in background before auto-locking.'**
  String get lockTimeoutDesc;

  /// No description provided for @timeoutImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get timeoutImmediately;

  /// No description provided for @timeout1Min.
  ///
  /// In en, this message translates to:
  /// **'1 Minute'**
  String get timeout1Min;

  /// No description provided for @timeout5Mins.
  ///
  /// In en, this message translates to:
  /// **'5 Minutes'**
  String get timeout5Mins;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get changePasswordSubtitle;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @currentPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get currentPasswordPlaceholder;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @newPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get newPasswordPlaceholder;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @confirmNewPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Re-enter new password'**
  String get confirmNewPasswordPlaceholder;

  /// No description provided for @savePassword.
  ///
  /// In en, this message translates to:
  /// **'Save Password'**
  String get savePassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully!'**
  String get passwordUpdated;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @passwordShort.
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 6 characters'**
  String get passwordShort;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeMinutesAgo(Object count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeHoursAgo(Object count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeDaysAgo(Object count);

  /// No description provided for @timeMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}mo ago'**
  String timeMonthsAgo(Object count);

  /// No description provided for @playingArchive.
  ///
  /// In en, this message translates to:
  /// **'Playing recording'**
  String get playingArchive;

  /// No description provided for @recordingEvent.
  ///
  /// In en, this message translates to:
  /// **'Event: {type}'**
  String recordingEvent(Object type);

  /// No description provided for @serverConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Server Configuration'**
  String get serverConfigTitle;

  /// No description provided for @serverConfigSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the API Gateway server address to connect with HubSight system.'**
  String get serverConfigSubtitle;

  /// No description provided for @serverUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'SERVER URL'**
  String get serverUrlLabel;

  /// No description provided for @serverUrlHint.
  ///
  /// In en, this message translates to:
  /// **'http://10.0.2.2:8088'**
  String get serverUrlHint;

  /// No description provided for @serverUrlHelp.
  ///
  /// In en, this message translates to:
  /// **'Example: http://192.168.1.100:8088 or https://cctv.yourdomain.com'**
  String get serverUrlHelp;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// No description provided for @connectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully connected to server!'**
  String get connectionSuccess;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to server. Please check the URL.'**
  String get connectionFailed;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @serverUrlEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter server URL'**
  String get serverUrlEmpty;

  /// No description provided for @serverUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid server URL (must start with http:// or https://)'**
  String get serverUrlInvalid;

  /// No description provided for @changeServer.
  ///
  /// In en, this message translates to:
  /// **'Change Server'**
  String get changeServer;

  /// No description provided for @serverConfigSetting.
  ///
  /// In en, this message translates to:
  /// **'Server Address Configuration'**
  String get serverConfigSetting;

  /// No description provided for @enrollHscfgTitle.
  ///
  /// In en, this message translates to:
  /// **'Zero-Config Enrollment (.hscfg)'**
  String get enrollHscfgTitle;

  /// No description provided for @enrollHscfgDesc.
  ///
  /// In en, this message translates to:
  /// **'Select the secure .hscfg container provided by your administrator and enter the 6-digit PIN to set up automatically.'**
  String get enrollHscfgDesc;

  /// No description provided for @pickHscfgFile.
  ///
  /// In en, this message translates to:
  /// **'Select .hscfg file'**
  String get pickHscfgFile;

  /// No description provided for @fileSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected: {filename}'**
  String fileSelected(Object filename);

  /// No description provided for @pinLabel.
  ///
  /// In en, this message translates to:
  /// **'SECURITY PIN (6 DIGITS)'**
  String get pinLabel;

  /// No description provided for @pinHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit PIN (e.g. 123456)'**
  String get pinHint;

  /// No description provided for @enrollButton.
  ///
  /// In en, this message translates to:
  /// **'Decrypt & Connect'**
  String get enrollButton;

  /// No description provided for @orManualSetup.
  ///
  /// In en, this message translates to:
  /// **'OR MANUAL GATEWAY SETUP'**
  String get orManualSetup;

  /// No description provided for @apiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'CLIENT API KEY'**
  String get apiKeyLabel;

  /// No description provided for @apiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'X-API-Key (e.g. hsc_live_app_...)'**
  String get apiKeyHint;

  /// No description provided for @twoFactorTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication (2FA)'**
  String get twoFactorTitle;

  /// No description provided for @twoFactorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit TOTP code from your Google Authenticator app.'**
  String get twoFactorSubtitle;

  /// No description provided for @twoFactorCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'VERIFICATION CODE (6 DIGITS)'**
  String get twoFactorCodeLabel;

  /// No description provided for @twoFactorCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 123456'**
  String get twoFactorCodeHint;

  /// No description provided for @useRecoveryCode.
  ///
  /// In en, this message translates to:
  /// **'Use backup recovery code'**
  String get useRecoveryCode;

  /// No description provided for @recoveryCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'BACKUP RECOVERY CODE'**
  String get recoveryCodeLabel;

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify & Login'**
  String get verifyButton;

  /// No description provided for @twoFactorFailed.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired 2FA verification code'**
  String get twoFactorFailed;

  /// No description provided for @sessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Devices & Active Sessions'**
  String get sessionsTitle;

  /// No description provided for @sessionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage and revoke active sessions on other devices'**
  String get sessionsSubtitle;

  /// No description provided for @currentSession.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get currentSession;

  /// No description provided for @revokeSession.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revokeSession;

  /// No description provided for @confirmRevokeSession.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to revoke this session? That device will be disconnected immediately.'**
  String get confirmRevokeSession;

  /// No description provided for @sessionRevokedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Session revoked successfully'**
  String get sessionRevokedSuccess;

  /// No description provided for @remoteRevokedAlert.
  ///
  /// In en, this message translates to:
  /// **'Your session was revoked remotely by administrator or another device.'**
  String get remoteRevokedAlert;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'System Maintenance'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceMessage.
  ///
  /// In en, this message translates to:
  /// **'Mobile app services are temporarily disabled for scheduled maintenance.'**
  String get maintenanceMessage;

  /// No description provided for @retryAfterCountdown.
  ///
  /// In en, this message translates to:
  /// **'Auto retry in: {seconds}s'**
  String retryAfterCountdown(Object seconds);

  /// No description provided for @retryNow.
  ///
  /// In en, this message translates to:
  /// **'Retry Now'**
  String get retryNow;

  /// No description provided for @multiViewTitle.
  ///
  /// In en, this message translates to:
  /// **'Multi-View Grid'**
  String get multiViewTitle;

  /// No description provided for @multiViewDesc.
  ///
  /// In en, this message translates to:
  /// **'Parallel WebRTC negotiation & battery optimization'**
  String get multiViewDesc;

  /// No description provided for @switchLayout.
  ///
  /// In en, this message translates to:
  /// **'Switch Layout'**
  String get switchLayout;

  /// No description provided for @cameraStoppedPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Camera Stopped'**
  String get cameraStoppedPlaceholder;

  /// No description provided for @liveStreamLoading.
  ///
  /// In en, this message translates to:
  /// **'Connecting live stream...'**
  String get liveStreamLoading;

  /// No description provided for @mustChangePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Change Required'**
  String get mustChangePasswordTitle;

  /// No description provided for @mustChangePasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'You are required to change your password before proceeding.'**
  String get mustChangePasswordDesc;

  /// No description provided for @errConfigInvalidPin.
  ///
  /// In en, this message translates to:
  /// **'PIN must be exactly 6 digits.'**
  String get errConfigInvalidPin;

  /// No description provided for @errConfigDecryptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Configuration decryption failed. Incorrect PIN or corrupted file.'**
  String get errConfigDecryptionFailed;

  /// No description provided for @errConfigInvalidSignature.
  ///
  /// In en, this message translates to:
  /// **'Invalid Ed25519 digital signature on configuration container.'**
  String get errConfigInvalidSignature;

  /// No description provided for @errAuthInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password.'**
  String get errAuthInvalidCredentials;

  /// No description provided for @errNetworkTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Please check your network.'**
  String get errNetworkTimeout;

  /// No description provided for @errNetworkUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the API Gateway server.'**
  String get errNetworkUnreachable;

  /// No description provided for @errSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get errSessionExpired;

  /// No description provided for @errAppKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Application API key is required. Please scan QR code or enroll .hscfg profile.'**
  String get errAppKeyRequired;

  /// No description provided for @errAppKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'Application API key is invalid or has been revoked. Please re-configure.'**
  String get errAppKeyInvalid;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again later.'**
  String get errGeneric;

  /// No description provided for @scanQrTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrTabTitle;

  /// No description provided for @scanQrDesc.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the HubSight configuration QR code provided by your administrator.'**
  String get scanQrDesc;

  /// No description provided for @scanQrPickImage.
  ///
  /// In en, this message translates to:
  /// **'Pick QR image from gallery'**
  String get scanQrPickImage;

  /// No description provided for @scanQrInvalidPayload.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code or not a HubSight configuration format.'**
  String get scanQrInvalidPayload;

  /// No description provided for @scanQrDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading configuration file...'**
  String get scanQrDownloading;

  /// No description provided for @scanQrChecksumMismatch.
  ///
  /// In en, this message translates to:
  /// **'SHA-256 checksum mismatch on downloaded configuration file.'**
  String get scanQrChecksumMismatch;

  /// No description provided for @scanQrEnterPinPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit PIN to unlock configuration'**
  String get scanQrEnterPinPrompt;

  /// No description provided for @scanQrConfigIdentified.
  ///
  /// In en, this message translates to:
  /// **'Recognized: {name}'**
  String scanQrConfigIdentified(Object name);

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to scan QR codes.'**
  String get cameraPermissionRequired;

  /// No description provided for @tabHscfgFile.
  ///
  /// In en, this message translates to:
  /// **'Config File (.hscfg)'**
  String get tabHscfgFile;

  /// No description provided for @loginOrDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get loginOrDivider;

  /// No description provided for @loginPasskeyBtn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Passkey'**
  String get loginPasskeyBtn;

  /// No description provided for @loginPasskeyUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your username before signing in with a Passkey.'**
  String get loginPasskeyUsernameRequired;

  /// No description provided for @loginPasskeyBtnFaceId.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Face ID'**
  String get loginPasskeyBtnFaceId;

  /// No description provided for @loginPasskeyBtnTouchId.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Touch ID'**
  String get loginPasskeyBtnTouchId;

  /// No description provided for @loginPasskeyBtnFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Fingerprint'**
  String get loginPasskeyBtnFingerprint;

  /// No description provided for @loginBiometricPrompt.
  ///
  /// In en, this message translates to:
  /// **'Authenticate with biometrics to sign in to HubSight'**
  String get loginBiometricPrompt;

  /// No description provided for @loginBiometricNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Biometric login is not configured on this device yet. Please sign in with password first to enable.'**
  String get loginBiometricNotConfigured;

  /// No description provided for @loginBiometricNotEnrolled.
  ///
  /// In en, this message translates to:
  /// **'No biometrics enrolled on this device. Please set up in device settings.'**
  String get loginBiometricNotEnrolled;

  /// No description provided for @loginBiometricNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Biometrics not supported or enrolled on this device.'**
  String get loginBiometricNotSupported;

  /// No description provided for @loginBiometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed or was cancelled.'**
  String get loginBiometricFailed;

  /// No description provided for @biometricEnrollPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric Sign-in?'**
  String get biometricEnrollPromptTitle;

  /// No description provided for @biometricEnrollPromptDesc.
  ///
  /// In en, this message translates to:
  /// **'Would you like to use biometrics to quickly sign in to HubSight next time?'**
  String get biometricEnrollPromptDesc;

  /// No description provided for @biometricEnrollEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable Now'**
  String get biometricEnrollEnable;

  /// No description provided for @biometricEnrollLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get biometricEnrollLater;

  /// No description provided for @biometricSettingsQuickLogin.
  ///
  /// In en, this message translates to:
  /// **'Quick Biometric Sign-in'**
  String get biometricSettingsQuickLogin;

  /// No description provided for @biometricSettingsQuickLoginDesc.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID or Fingerprint to sign in instantly without typing password.'**
  String get biometricSettingsQuickLoginDesc;

  /// No description provided for @passkeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric & Security Keys'**
  String get passkeyTitle;

  /// No description provided for @passkeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fast passwordless sign-in with Face ID, Touch ID, Windows Hello or Device PIN.'**
  String get passkeySubtitle;

  /// No description provided for @addPasskeyBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Device'**
  String get addPasskeyBtn;

  /// No description provided for @noPasskeys.
  ///
  /// In en, this message translates to:
  /// **'No authenticator devices registered on this account yet.'**
  String get noPasskeys;

  /// No description provided for @passkeyCreated.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get passkeyCreated;

  /// No description provided for @passkeyLastUsed.
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get passkeyLastUsed;

  /// No description provided for @passkeyNeverUsed.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get passkeyNeverUsed;

  /// No description provided for @renamePasskey.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renamePasskey;

  /// No description provided for @deletePasskey.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get deletePasskey;

  /// No description provided for @passkeyNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. iPhone Face ID / MacBook Touch ID'**
  String get passkeyNamePlaceholder;

  /// No description provided for @passkeyNamePrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter a label for this device:'**
  String get passkeyNamePrompt;

  /// No description provided for @confirmDeletePasskey.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this authenticator device?'**
  String get confirmDeletePasskey;

  /// No description provided for @passkeyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Device updated successfully!'**
  String get passkeyUpdated;

  /// No description provided for @passkeyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Authenticator device removed!'**
  String get passkeyDeleted;

  /// No description provided for @passkeyAdded.
  ///
  /// In en, this message translates to:
  /// **'Authenticator device registered successfully!'**
  String get passkeyAdded;

  /// No description provided for @passkeyEnrollDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Authenticator Device'**
  String get passkeyEnrollDialogTitle;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme Appearance'**
  String get themeTitle;

  /// No description provided for @themeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize light, dark or automatic system appearance'**
  String get themeSubtitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystemDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically matches device setting'**
  String get themeSystemDesc;

  /// No description provided for @themeLightDesc.
  ///
  /// In en, this message translates to:
  /// **'Optimized for well-lit environments'**
  String get themeLightDesc;

  /// No description provided for @themeDarkDesc.
  ///
  /// In en, this message translates to:
  /// **'Easy on the eyes and saves battery on OLED'**
  String get themeDarkDesc;

  /// No description provided for @ptzControl.
  ///
  /// In en, this message translates to:
  /// **'PTZ Control'**
  String get ptzControl;

  /// No description provided for @ptzPadTitle.
  ///
  /// In en, this message translates to:
  /// **'Pan / Tilt / Zoom Control'**
  String get ptzPadTitle;

  /// No description provided for @onvifBadge.
  ///
  /// In en, this message translates to:
  /// **'ONVIF'**
  String get onvifBadge;

  /// No description provided for @ptzBadge.
  ///
  /// In en, this message translates to:
  /// **'PTZ'**
  String get ptzBadge;

  /// No description provided for @onvifDiscovery.
  ///
  /// In en, this message translates to:
  /// **'ONVIF Discovery'**
  String get onvifDiscovery;

  /// No description provided for @onvifDiscoverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Probe network cameras, firmware, profiles & PTZ'**
  String get onvifDiscoverySubtitle;

  /// No description provided for @probeCamera.
  ///
  /// In en, this message translates to:
  /// **'Probe Camera'**
  String get probeCamera;

  /// No description provided for @probeHost.
  ///
  /// In en, this message translates to:
  /// **'Host / IP Address'**
  String get probeHost;

  /// No description provided for @probePort.
  ///
  /// In en, this message translates to:
  /// **'ONVIF Port'**
  String get probePort;

  /// No description provided for @probeUsername.
  ///
  /// In en, this message translates to:
  /// **'ONVIF Username'**
  String get probeUsername;

  /// No description provided for @probePassword.
  ///
  /// In en, this message translates to:
  /// **'ONVIF Password'**
  String get probePassword;

  /// No description provided for @probeSuccess.
  ///
  /// In en, this message translates to:
  /// **'ONVIF probe successful'**
  String get probeSuccess;

  /// No description provided for @probeFailed.
  ///
  /// In en, this message translates to:
  /// **'ONVIF probe failed'**
  String get probeFailed;

  /// No description provided for @presetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Preset Positions'**
  String get presetsTitle;

  /// No description provided for @addPreset.
  ///
  /// In en, this message translates to:
  /// **'Save Position'**
  String get addPreset;

  /// No description provided for @presetNamePrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter preset point name:'**
  String get presetNamePrompt;

  /// No description provided for @biometricFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get biometricFingerprint;

  /// No description provided for @biometricIris.
  ///
  /// In en, this message translates to:
  /// **'Iris'**
  String get biometricIris;

  /// No description provided for @biometricGeneral.
  ///
  /// In en, this message translates to:
  /// **'Biometrics'**
  String get biometricGeneral;

  /// No description provided for @biometricDefaultReason.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to unlock HubSight'**
  String get biometricDefaultReason;

  /// No description provided for @lockBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate {biometric} to unlock HubSight'**
  String lockBiometricReason(Object biometric);

  /// No description provided for @lockPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'Confirmation PIN does not match. Please try again.'**
  String get lockPinMismatch;

  /// No description provided for @lockNoPinPrompt.
  ///
  /// In en, this message translates to:
  /// **'No PIN set. Please unlock using {biometric}'**
  String lockNoPinPrompt(Object biometric);

  /// No description provided for @lockPinIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN code'**
  String get lockPinIncorrect;

  /// No description provided for @lockEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN code to unlock'**
  String get lockEnterPin;

  /// No description provided for @lockConfirmPin.
  ///
  /// In en, this message translates to:
  /// **'Re-enter PIN to confirm'**
  String get lockConfirmPin;

  /// No description provided for @lockSetNewPin.
  ///
  /// In en, this message translates to:
  /// **'Set up new PIN code'**
  String get lockSetNewPin;

  /// No description provided for @lockEnterPinOrBiometric.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN or use {biometric}'**
  String lockEnterPinOrBiometric(Object biometric);

  /// No description provided for @lockLogoutAccount.
  ///
  /// In en, this message translates to:
  /// **'Logout of account'**
  String get lockLogoutAccount;

  /// No description provided for @loginQuickBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Quick sign-in with {biometric} to HubSight'**
  String loginQuickBiometricReason(Object biometric);

  /// No description provided for @serverNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Server not configured'**
  String get serverNotConfigured;

  /// No description provided for @configureServerNow.
  ///
  /// In en, this message translates to:
  /// **'Configure server now'**
  String get configureServerNow;

  /// No description provided for @recoveryCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 8-16 char recovery code'**
  String get recoveryCodeHint;

  /// No description provided for @useTotpCode.
  ///
  /// In en, this message translates to:
  /// **'Use 6-digit verification code'**
  String get useTotpCode;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// No description provided for @onvifModeSystemCameras.
  ///
  /// In en, this message translates to:
  /// **'Cameras in system'**
  String get onvifModeSystemCameras;

  /// No description provided for @onvifModeCustomIp.
  ///
  /// In en, this message translates to:
  /// **'Custom IP/Host'**
  String get onvifModeCustomIp;

  /// No description provided for @onvifHostHint.
  ///
  /// In en, this message translates to:
  /// **'192.168.1.100 or hostname'**
  String get onvifHostHint;

  /// No description provided for @onvifPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'ONVIF password (if any)'**
  String get onvifPasswordHint;

  /// No description provided for @probingCamera.
  ///
  /// In en, this message translates to:
  /// **'Probing...'**
  String get probingCamera;

  /// No description provided for @onvifPtzSupported.
  ///
  /// In en, this message translates to:
  /// **'PTZ Supported'**
  String get onvifPtzSupported;

  /// No description provided for @onvifDeviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device Information'**
  String get onvifDeviceInfo;

  /// No description provided for @onvifManufacturer.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get onvifManufacturer;

  /// No description provided for @onvifModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get onvifModel;

  /// No description provided for @onvifFirmwareVersion.
  ///
  /// In en, this message translates to:
  /// **'Firmware Version'**
  String get onvifFirmwareVersion;

  /// No description provided for @onvifSerialNumber.
  ///
  /// In en, this message translates to:
  /// **'Serial Number'**
  String get onvifSerialNumber;

  /// No description provided for @onvifMediaProfiles.
  ///
  /// In en, this message translates to:
  /// **'Media Profiles'**
  String get onvifMediaProfiles;

  /// No description provided for @onvifNoProfiles.
  ///
  /// In en, this message translates to:
  /// **'Could not extract media profiles.'**
  String get onvifNoProfiles;

  /// No description provided for @onvifRtspCopied.
  ///
  /// In en, this message translates to:
  /// **'RTSP Stream URI copied to clipboard!'**
  String get onvifRtspCopied;

  /// No description provided for @aiAlertNotification.
  ///
  /// In en, this message translates to:
  /// **'AI Alert: {event} at camera {camera}'**
  String aiAlertNotification(Object camera, Object event);

  /// No description provided for @allCameras.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCameras;

  /// No description provided for @recentRecognitions.
  ///
  /// In en, this message translates to:
  /// **'Recent Recognition Logs'**
  String get recentRecognitions;

  /// No description provided for @eventsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} events'**
  String eventsCount(Object count);

  /// No description provided for @noRecognitionData.
  ///
  /// In en, this message translates to:
  /// **'No facial recognition data available'**
  String get noRecognitionData;

  /// No description provided for @stranger.
  ///
  /// In en, this message translates to:
  /// **'Stranger'**
  String get stranger;

  /// No description provided for @noActiveStreamingCameras.
  ///
  /// In en, this message translates to:
  /// **'No active cameras available for live streaming'**
  String get noActiveStreamingCameras;

  /// No description provided for @ptzPresetHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Front Gate, Window, Backyard'**
  String get ptzPresetHint;

  /// No description provided for @ptzPresetSaved.
  ///
  /// In en, this message translates to:
  /// **'Preset saved: {name}'**
  String ptzPresetSaved(Object name);

  /// No description provided for @ptzPresetSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save preset: {error}'**
  String ptzPresetSaveFailed(Object error);

  /// No description provided for @ptzDeletePresetTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Preset'**
  String get ptzDeletePresetTitle;

  /// No description provided for @ptzDeletePresetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete preset \"{name}\"?'**
  String ptzDeletePresetConfirm(Object name);

  /// No description provided for @ptzPresetDeleted.
  ///
  /// In en, this message translates to:
  /// **'Preset deleted: {name}'**
  String ptzPresetDeleted(Object name);

  /// No description provided for @ptzPresetDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete preset: {error}'**
  String ptzPresetDeleteFailed(Object error);

  /// No description provided for @ptzCommandFailed.
  ///
  /// In en, this message translates to:
  /// **'PTZ command failed: {error}'**
  String ptzCommandFailed(Object error);

  /// No description provided for @ptzHoldInstruction.
  ///
  /// In en, this message translates to:
  /// **'Press and hold arrow buttons to pan/tilt camera, release to stop.'**
  String get ptzHoldInstruction;

  /// No description provided for @ptzNoPresets.
  ///
  /// In en, this message translates to:
  /// **'No presets saved for this camera yet.'**
  String get ptzNoPresets;

  /// No description provided for @ptzMovingTo.
  ///
  /// In en, this message translates to:
  /// **'Moving camera to: {name}'**
  String ptzMovingTo(Object name);

  /// No description provided for @ptzMoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to move camera: {error}'**
  String ptzMoveFailed(Object error);

  /// No description provided for @webrtcErrBadGateway.
  ///
  /// In en, this message translates to:
  /// **'Server or camera connection temporarily disrupted (502 Bad Gateway). Retrying...'**
  String get webrtcErrBadGateway;

  /// No description provided for @webrtcErrNotFound.
  ///
  /// In en, this message translates to:
  /// **'Camera does not exist or has been removed from system.'**
  String get webrtcErrNotFound;

  /// No description provided for @webrtcErrUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Session expired or you do not have permission to view this camera.'**
  String get webrtcErrUnauthorized;

  /// No description provided for @webrtcErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server. Please check your network connection.'**
  String get webrtcErrNetwork;

  /// No description provided for @webrtcErrConnection.
  ///
  /// In en, this message translates to:
  /// **'Camera connection error: {error}'**
  String webrtcErrConnection(Object error);

  /// No description provided for @webrtcReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting video stream automatically ({count}/{max})...'**
  String webrtcReconnecting(Object count, Object max);

  /// No description provided for @webrtcErrSdkNotReady.
  ///
  /// In en, this message translates to:
  /// **'SDK has not been initialized'**
  String get webrtcErrSdkNotReady;

  /// No description provided for @webrtcErrStreamFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to live stream.'**
  String get webrtcErrStreamFailed;

  /// No description provided for @fallAlertWarning.
  ///
  /// In en, this message translates to:
  /// **'WARNING: FALL DETECTED ({count})'**
  String fallAlertWarning(Object count);

  /// No description provided for @webrtcConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting WebRTC (WHEP)...'**
  String get webrtcConnecting;

  /// No description provided for @webrtcStreamUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live stream unavailable'**
  String get webrtcStreamUnavailable;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @noUnreadNotifications.
  ///
  /// In en, this message translates to:
  /// **'No unread notifications'**
  String get noUnreadNotifications;

  /// No description provided for @noUnreadNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'You have reviewed all security alerts'**
  String get noUnreadNotificationsDesc;

  /// No description provided for @noNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Security alerts and AI events will appear here'**
  String get noNotificationsDesc;

  /// No description provided for @passkeyDefaultDeviceName.
  ///
  /// In en, this message translates to:
  /// **'{biometric} on this device'**
  String passkeyDefaultDeviceName(Object biometric);

  /// No description provided for @securitySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'App Security'**
  String get securitySectionTitle;

  /// No description provided for @noOtherSessions.
  ///
  /// In en, this message translates to:
  /// **'No other active sessions'**
  String get noOtherSessions;

  /// No description provided for @thisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get thisDevice;

  /// No description provided for @otherSessionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} other active sessions'**
  String otherSessionsCount(Object count);

  /// No description provided for @tapToCollapse.
  ///
  /// In en, this message translates to:
  /// **'Tap to collapse'**
  String get tapToCollapse;

  /// No description provided for @tapToManageAndRevoke.
  ///
  /// In en, this message translates to:
  /// **'Tap to manage and revoke'**
  String get tapToManageAndRevoke;

  /// No description provided for @genericDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get genericDevice;

  /// No description provided for @changePinTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Security PIN'**
  String get changePinTitle;

  /// No description provided for @changePinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your backup 4-digit PIN'**
  String get changePinSubtitle;

  /// No description provided for @pinUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'New PIN code updated successfully'**
  String get pinUpdatedSuccess;

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get notConfigured;

  /// No description provided for @serverProfileActive.
  ///
  /// In en, this message translates to:
  /// **'Profile: {name} • Active'**
  String serverProfileActive(Object name);

  /// No description provided for @gatewayNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Gateway port not connected'**
  String get gatewayNotConnected;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of this account?'**
  String get confirmLogout;

  /// No description provided for @configPickFileError.
  ///
  /// In en, this message translates to:
  /// **'Could not select file: {error}'**
  String configPickFileError(Object error);

  /// No description provided for @configQrAnalyzeError.
  ///
  /// In en, this message translates to:
  /// **'Error analyzing QR image: {error}'**
  String configQrAnalyzeError(Object error);

  /// No description provided for @configNoDataFromServer.
  ///
  /// In en, this message translates to:
  /// **'No data returned from configuration server.'**
  String get configNoDataFromServer;

  /// No description provided for @configNoFileSelectedError.
  ///
  /// In en, this message translates to:
  /// **'No configuration file selected. Please go back to the previous step.'**
  String get configNoFileSelectedError;

  /// No description provided for @configDecryptingSignature.
  ///
  /// In en, this message translates to:
  /// **'Decrypting container and verifying digital signature...'**
  String get configDecryptingSignature;

  /// No description provided for @configSavingSystem.
  ///
  /// In en, this message translates to:
  /// **'Saving system configuration...'**
  String get configSavingSystem;

  /// No description provided for @configSuccessLoginPrompt.
  ///
  /// In en, this message translates to:
  /// **'Server configured successfully! Please log in.'**
  String get configSuccessLoginPrompt;

  /// No description provided for @configSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving configuration: {error}'**
  String configSaveError(Object error);

  /// No description provided for @configStepWelcome.
  ///
  /// In en, this message translates to:
  /// **'HubSight Setup'**
  String get configStepWelcome;

  /// No description provided for @configStepMethod.
  ///
  /// In en, this message translates to:
  /// **'Connection Method'**
  String get configStepMethod;

  /// No description provided for @configStepPickFile.
  ///
  /// In en, this message translates to:
  /// **'Select Config File'**
  String get configStepPickFile;

  /// No description provided for @configStepScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get configStepScanQr;

  /// No description provided for @configStepPin.
  ///
  /// In en, this message translates to:
  /// **'Security PIN'**
  String get configStepPin;

  /// No description provided for @configStepSummary.
  ///
  /// In en, this message translates to:
  /// **'Confirm Configuration'**
  String get configStepSummary;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @configWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to HubSight'**
  String get configWelcomeTitle;

  /// No description provided for @configWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To connect the app to your surveillance server, please import the secure configuration container (.hscfg) or scan the QR code provided by your administrator.'**
  String get configWelcomeSubtitle;

  /// No description provided for @configFeatureE2eeTitle.
  ///
  /// In en, this message translates to:
  /// **'Multi-layer End-to-End Encryption'**
  String get configFeatureE2eeTitle;

  /// No description provided for @configFeatureE2eeDesc.
  ///
  /// In en, this message translates to:
  /// **'Protected by Argon2id key derivation and military-grade AES-256-GCM encryption.'**
  String get configFeatureE2eeDesc;

  /// No description provided for @configFeatureEd25519Title.
  ///
  /// In en, this message translates to:
  /// **'Ed25519 Digital Signature Verification'**
  String get configFeatureEd25519Title;

  /// No description provided for @configFeatureEd25519Desc.
  ///
  /// In en, this message translates to:
  /// **'Guarantees container authenticity, preventing tampering or unauthorized server redirection.'**
  String get configFeatureEd25519Desc;

  /// No description provided for @configFeatureZeroConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Zero-Config Setup'**
  String get configFeatureZeroConfigTitle;

  /// No description provided for @configFeatureZeroConfigDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically configures Gateway, WebSocket Relay, and WebRTC in seconds.'**
  String get configFeatureZeroConfigDesc;

  /// No description provided for @configStartSetup.
  ///
  /// In en, this message translates to:
  /// **'Start Setup'**
  String get configStartSetup;

  /// No description provided for @configSelectMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Connection Method'**
  String get configSelectMethodTitle;

  /// No description provided for @configSelectMethodDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose the most convenient method to import connection parameters into the app:'**
  String get configSelectMethodDesc;

  /// No description provided for @configMethodQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Configuration QR'**
  String get configMethodQrTitle;

  /// No description provided for @configMethodQrDesc.
  ///
  /// In en, this message translates to:
  /// **'Use device camera to scan configuration QR code directly from computer screen or saved photo.'**
  String get configMethodQrDesc;

  /// No description provided for @configMethodRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get configMethodRecommended;

  /// No description provided for @configMethodFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Config File (.hscfg)'**
  String get configMethodFileTitle;

  /// No description provided for @configMethodFileDesc.
  ///
  /// In en, this message translates to:
  /// **'Select the secure container file (.hscfg) downloaded on your device.'**
  String get configMethodFileDesc;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @configPickFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Config File (.hscfg)'**
  String get configPickFileTitle;

  /// No description provided for @configPickFileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the secure container file exported from the system by your administrator.'**
  String get configPickFileSubtitle;

  /// No description provided for @configTapToPickFile.
  ///
  /// In en, this message translates to:
  /// **'Tap to select .hscfg file'**
  String get configTapToPickFile;

  /// No description provided for @configFileSizeKb.
  ///
  /// In en, this message translates to:
  /// **'File size: {size} KB'**
  String configFileSizeKb(Object size);

  /// No description provided for @configStandardFormatSupport.
  ///
  /// In en, this message translates to:
  /// **'Supports standard .hscfg container'**
  String get configStandardFormatSupport;

  /// No description provided for @configReadyToDecrypt.
  ///
  /// In en, this message translates to:
  /// **'READY TO DECRYPT'**
  String get configReadyToDecrypt;

  /// No description provided for @configPickAnotherFile.
  ///
  /// In en, this message translates to:
  /// **'Choose another file'**
  String get configPickAnotherFile;

  /// No description provided for @configQrInstruction.
  ///
  /// In en, this message translates to:
  /// **'Point camera at configuration QR code to scan automatically'**
  String get configQrInstruction;

  /// No description provided for @configFlashTooltip.
  ///
  /// In en, this message translates to:
  /// **'Flashlight'**
  String get configFlashTooltip;

  /// No description provided for @configQrPickGallery.
  ///
  /// In en, this message translates to:
  /// **'Pick QR from gallery'**
  String get configQrPickGallery;

  /// No description provided for @configSwitchCameraTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get configSwitchCameraTooltip;

  /// No description provided for @configQrFallbackName.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get configQrFallbackName;

  /// No description provided for @configEnterPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Security PIN (6 digits)'**
  String get configEnterPinTitle;

  /// No description provided for @configEnterPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit PIN provided by your administrator to unpack and decrypt data container.'**
  String get configEnterPinSubtitle;

  /// No description provided for @configDecryptButton.
  ///
  /// In en, this message translates to:
  /// **'Unpack & Decrypt'**
  String get configDecryptButton;

  /// No description provided for @configDecryptionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Decryption & Verification Successful'**
  String get configDecryptionSuccess;

  /// No description provided for @configSignatureValid.
  ///
  /// In en, this message translates to:
  /// **'Valid Ed25519 digital signature. Authentic file.'**
  String get configSignatureValid;

  /// No description provided for @configConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Configuration Details'**
  String get configConfirmTitle;

  /// No description provided for @configConfirmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review connection parameters carefully before saving and activating application:'**
  String get configConfirmSubtitle;

  /// No description provided for @configSummarySystemName.
  ///
  /// In en, this message translates to:
  /// **'System Name'**
  String get configSummarySystemName;

  /// No description provided for @configSummaryConfigId.
  ///
  /// In en, this message translates to:
  /// **'Config ID'**
  String get configSummaryConfigId;

  /// No description provided for @configSummaryGateway.
  ///
  /// In en, this message translates to:
  /// **'Gateway Server'**
  String get configSummaryGateway;

  /// No description provided for @configSummaryClientName.
  ///
  /// In en, this message translates to:
  /// **'Client Name'**
  String get configSummaryClientName;

  /// No description provided for @configSummaryCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Created By'**
  String get configSummaryCreatedBy;

  /// No description provided for @configSummaryCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get configSummaryCreatedAt;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @configSummaryProfileVersion.
  ///
  /// In en, this message translates to:
  /// **'Profile Version'**
  String get configSummaryProfileVersion;

  /// No description provided for @configConfirmAndProceed.
  ///
  /// In en, this message translates to:
  /// **'Accept & Proceed to Login'**
  String get configConfirmAndProceed;

  /// No description provided for @configResetFromScratch.
  ///
  /// In en, this message translates to:
  /// **'Reset from Beginning'**
  String get configResetFromScratch;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Intelligent Video Surveillance & Management'**
  String get splashTagline;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enterprise CCTV & AI Security Platform'**
  String get splashSubtitle;

  /// No description provided for @splashInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing security environment...'**
  String get splashInitializing;

  /// No description provided for @liveTab.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get liveTab;

  /// No description provided for @playbackTab.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playbackTab;

  /// No description provided for @ptzControlPanel.
  ///
  /// In en, this message translates to:
  /// **'PTZ Controls'**
  String get ptzControlPanel;

  /// No description provided for @ptzSwipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe video to steer camera'**
  String get ptzSwipeHint;

  /// No description provided for @ptzQuickAction.
  ///
  /// In en, this message translates to:
  /// **'PTZ Control'**
  String get ptzQuickAction;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
