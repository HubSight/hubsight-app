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

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again later.'**
  String get errGeneric;
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
