// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HubSight';

  @override
  String get languageSelector => 'EN English';

  @override
  String get languageBadge => 'EN EN';

  @override
  String get loginSubtitle => 'Login to manage devices and review';

  @override
  String get usernameLabel => 'USERNAME';

  @override
  String get usernameHint => 'admin';

  @override
  String get passwordLabel => 'PASSWORD';

  @override
  String get passwordHint => '••••••••••••';

  @override
  String get loginButton => 'Login';

  @override
  String get footerVersion => 'HubSight v1.0.0+sha-91d8e0d.';

  @override
  String get footerCopyright => '© 2026 by Anh Quoc Tran';

  @override
  String get dashboardTitle => 'HubSight Live Dashboard';

  @override
  String get dashboardNoCameras => 'No cameras found';

  @override
  String get cameraOffline => 'Camera Offline';

  @override
  String get cameraOnline => 'Active (Online)';

  @override
  String get cameraStopped => 'Offline / Stopped';

  @override
  String get selectCamera => 'Select camera';

  @override
  String get deviceLabel => 'Device:';

  @override
  String get dateLabel => 'Date:';

  @override
  String get recordsLabel => 'Recordings:';

  @override
  String get noData => 'No data';

  @override
  String get loading => 'Loading...';

  @override
  String recordsCount(Object count) {
    return '$count recordings';
  }

  @override
  String get eventTimelineTitle => 'Event Timeline (Event-based Playback)';

  @override
  String get noEventsToday => 'No unusual events recorded on this day';

  @override
  String eventsToday(Object count) {
    return '$count events recorded';
  }

  @override
  String filterAll(Object count) {
    return 'All ($count)';
  }

  @override
  String get filterMorning => '00-12h';

  @override
  String get filterAfternoon => '12-18h';

  @override
  String get filterEvening => '18-24h';

  @override
  String get live => 'LIVE';

  @override
  String get cameraStoppedStatus => 'OFFLINE';

  @override
  String cameraStoppedTitle(Object camera) {
    return '“$camera” is offline';
  }

  @override
  String get cameraStoppedDesc =>
      'Live stream is offline. Choose another camera from the list, or wait for admin to restart it.';

  @override
  String get notificationTitle => 'Notifications';

  @override
  String get notificationSubtitle =>
      'Person recognition history & security alerts';

  @override
  String filterUnread(Object count) {
    return 'Unread ($count)';
  }

  @override
  String get deleteAll => 'Delete all';

  @override
  String get viewPlayback => 'Watch camera';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get confirmDeleteAll =>
      'Are you sure you want to clear all notifications?';

  @override
  String get confirmDelete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get menuHome => 'Home';

  @override
  String get menuDevices => 'Devices';

  @override
  String get menuMembers => 'Members';

  @override
  String get menuPlayback => 'Playback';

  @override
  String get menuNvrMonitor => 'NVR Monitor';

  @override
  String get menuConnectionPool => 'Connection Pool';

  @override
  String get menuLanguage => 'Language';

  @override
  String get sidebarSubtitle => 'Live Surveillance';

  @override
  String get adminRole => 'ADMIN';

  @override
  String get logout => 'Logout';

  @override
  String get settingsTitle => 'Device & Security Settings';

  @override
  String get settingsSubtitle =>
      'Customize notifications, timezone and app lock security';

  @override
  String get appModeTitle => 'Web Browser Mode';

  @override
  String get appModeDesc =>
      'Install the app as a standalone application for the smoothest lock experience.';

  @override
  String get timezoneTitle => 'Display Timezone';

  @override
  String get timezoneDesc =>
      'Timezone used to display time in notifications and logs (Default: UTC+7).';

  @override
  String get selectTimezone => 'Select timezone';

  @override
  String get pushSettingsTitle => 'Push Notification Settings';

  @override
  String get pushSettingsSubtitle =>
      'Choose event categories for push notifications';

  @override
  String get pushFamily => 'Familiar Persons (Family, Guests)';

  @override
  String get pushFamilyDesc =>
      'Notify when camera recognizes family members or regular guests.';

  @override
  String get pushStranger => 'Security Alerts & Strangers';

  @override
  String get pushStrangerDesc =>
      'Includes strangers, intrusions, falls, weapons, fire/smoke...';

  @override
  String get pushSystem => 'System Notifications';

  @override
  String get pushSystemDesc =>
      'Alerts on NVR system status, connection errors or full storage.';

  @override
  String get lockOnBackground => 'Lock on Background';

  @override
  String get lockOnBackgroundDesc =>
      'Automatically lock screen when app is hidden or minimized.';

  @override
  String get biometricUnlock => 'Biometric Unlock (Face ID / Fingerprint)';

  @override
  String get biometricUnlockDesc =>
      'Use WebAuthn biometric sensors or device PIN for quick unlock.';

  @override
  String get lockTimeoutTitle => 'Screen Lock Timeout';

  @override
  String get lockTimeoutDesc =>
      'Choose how long the app stays in background before auto-locking.';

  @override
  String get timeoutImmediately => 'Immediately';

  @override
  String get timeout1Min => '1 Minute';

  @override
  String get timeout5Mins => '5 Minutes';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get changePasswordSubtitle => 'Update your account password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get currentPasswordPlaceholder => 'Enter current password';

  @override
  String get newPassword => 'New Password';

  @override
  String get newPasswordPlaceholder => 'At least 6 characters';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get confirmNewPasswordPlaceholder => 'Re-enter new password';

  @override
  String get savePassword => 'Save Password';

  @override
  String get passwordUpdated => 'Password updated successfully!';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get passwordShort => 'New password must be at least 6 characters';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(Object count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(Object count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(Object count) {
    return '${count}d ago';
  }

  @override
  String timeMonthsAgo(Object count) {
    return '${count}mo ago';
  }

  @override
  String get playingArchive => 'Playing recording';

  @override
  String recordingEvent(Object type) {
    return 'Event: $type';
  }

  @override
  String get serverConfigTitle => 'Server Configuration';

  @override
  String get serverConfigSubtitle =>
      'Enter the API Gateway server address to connect with HubSight system.';

  @override
  String get serverUrlLabel => 'SERVER URL';

  @override
  String get serverUrlHint => 'http://10.0.2.2:8088';

  @override
  String get serverUrlHelp =>
      'Example: http://192.168.1.100:8088 or https://cctv.yourdomain.com';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get connectionSuccess => 'Successfully connected to server!';

  @override
  String get connectionFailed =>
      'Failed to connect to server. Please check the URL.';

  @override
  String get continueButton => 'Continue';

  @override
  String get serverUrlEmpty => 'Please enter server URL';

  @override
  String get serverUrlInvalid =>
      'Invalid server URL (must start with http:// or https://)';

  @override
  String get changeServer => 'Change Server';

  @override
  String get serverConfigSetting => 'Server Address Configuration';

  @override
  String get enrollHscfgTitle => 'Zero-Config Enrollment (.hscfg)';

  @override
  String get enrollHscfgDesc =>
      'Select the secure .hscfg container provided by your administrator and enter the 6-digit PIN to set up automatically.';

  @override
  String get pickHscfgFile => 'Select .hscfg file';

  @override
  String fileSelected(Object filename) {
    return 'Selected: $filename';
  }

  @override
  String get pinLabel => 'SECURITY PIN (6 DIGITS)';

  @override
  String get pinHint => 'Enter 6-digit PIN (e.g. 123456)';

  @override
  String get enrollButton => 'Decrypt & Connect';

  @override
  String get orManualSetup => 'OR MANUAL GATEWAY SETUP';

  @override
  String get apiKeyLabel => 'CLIENT API KEY';

  @override
  String get apiKeyHint => 'X-API-Key (e.g. hsc_live_app_...)';

  @override
  String get twoFactorTitle => 'Two-Factor Authentication (2FA)';

  @override
  String get twoFactorSubtitle =>
      'Enter the 6-digit TOTP code from your Google Authenticator app.';

  @override
  String get twoFactorCodeLabel => 'VERIFICATION CODE (6 DIGITS)';

  @override
  String get twoFactorCodeHint => 'e.g. 123456';

  @override
  String get useRecoveryCode => 'Use backup recovery code';

  @override
  String get recoveryCodeLabel => 'BACKUP RECOVERY CODE';

  @override
  String get verifyButton => 'Verify & Login';

  @override
  String get twoFactorFailed => 'Invalid or expired 2FA verification code';

  @override
  String get sessionsTitle => 'Devices & Active Sessions';

  @override
  String get sessionsSubtitle =>
      'Manage and revoke active sessions on other devices';

  @override
  String get currentSession => 'This device';

  @override
  String get revokeSession => 'Revoke';

  @override
  String get confirmRevokeSession =>
      'Are you sure you want to revoke this session? That device will be disconnected immediately.';

  @override
  String get sessionRevokedSuccess => 'Session revoked successfully';

  @override
  String get remoteRevokedAlert =>
      'Your session was revoked remotely by administrator or another device.';

  @override
  String get maintenanceTitle => 'System Maintenance';

  @override
  String get maintenanceMessage =>
      'Mobile app services are temporarily disabled for scheduled maintenance.';

  @override
  String retryAfterCountdown(Object seconds) {
    return 'Auto retry in: ${seconds}s';
  }

  @override
  String get retryNow => 'Retry Now';

  @override
  String get multiViewTitle => 'Multi-View Grid';

  @override
  String get multiViewDesc =>
      'Parallel WebRTC negotiation & battery optimization';

  @override
  String get switchLayout => 'Switch Layout';

  @override
  String get cameraStoppedPlaceholder => 'Camera Stopped';

  @override
  String get liveStreamLoading => 'Connecting live stream...';

  @override
  String get mustChangePasswordTitle => 'Password Change Required';

  @override
  String get mustChangePasswordDesc =>
      'You are required to change your password before proceeding.';

  @override
  String get errConfigInvalidPin => 'PIN must be exactly 6 digits.';

  @override
  String get errConfigDecryptionFailed =>
      'Configuration decryption failed. Incorrect PIN or corrupted file.';

  @override
  String get errConfigInvalidSignature =>
      'Invalid Ed25519 digital signature on configuration container.';

  @override
  String get errAuthInvalidCredentials => 'Invalid username or password.';

  @override
  String get errNetworkTimeout =>
      'Connection timed out. Please check your network.';

  @override
  String get errNetworkUnreachable => 'Unable to reach the API Gateway server.';

  @override
  String get errSessionExpired => 'Session expired. Please log in again.';

  @override
  String get errAppKeyRequired =>
      'Application API key is required. Please scan QR code or enroll .hscfg profile.';

  @override
  String get errAppKeyInvalid =>
      'Application API key is invalid or has been revoked. Please re-configure.';

  @override
  String get errGeneric => 'An error occurred. Please try again later.';

  @override
  String get scanQrTabTitle => 'Scan QR Code';

  @override
  String get scanQrDesc =>
      'Point your camera at the HubSight configuration QR code provided by your administrator.';

  @override
  String get scanQrPickImage => 'Pick QR image from gallery';

  @override
  String get scanQrInvalidPayload =>
      'Invalid QR code or not a HubSight configuration format.';

  @override
  String get scanQrDownloading => 'Downloading configuration file...';

  @override
  String get scanQrChecksumMismatch =>
      'SHA-256 checksum mismatch on downloaded configuration file.';

  @override
  String get scanQrEnterPinPrompt =>
      'Enter 6-digit PIN to unlock configuration';

  @override
  String scanQrConfigIdentified(Object name) {
    return 'Recognized: $name';
  }

  @override
  String get cameraPermissionRequired =>
      'Camera permission is required to scan QR codes.';

  @override
  String get tabHscfgFile => 'Config File (.hscfg)';

  @override
  String get loginOrDivider => 'OR';

  @override
  String get loginPasskeyBtn => 'Sign in with Biometrics / Face ID';

  @override
  String get loginPasskeyBtnFaceId => 'Sign in with Face ID';

  @override
  String get loginPasskeyBtnTouchId => 'Sign in with Touch ID';

  @override
  String get loginPasskeyBtnFingerprint => 'Sign in with Fingerprint';

  @override
  String get loginBiometricPrompt =>
      'Authenticate with biometrics to sign in to HubSight';

  @override
  String get loginBiometricNotConfigured =>
      'Biometric login is not configured on this device yet. Please sign in with password first to enable.';

  @override
  String get loginBiometricNotEnrolled =>
      'No biometrics enrolled on this device. Please set up in device settings.';

  @override
  String get loginBiometricNotSupported =>
      'Biometrics not supported or enrolled on this device.';

  @override
  String get loginBiometricFailed =>
      'Biometric authentication failed or was cancelled.';

  @override
  String get biometricEnrollPromptTitle => 'Enable Biometric Sign-in?';

  @override
  String get biometricEnrollPromptDesc =>
      'Would you like to use biometrics to quickly sign in to HubSight next time?';

  @override
  String get biometricEnrollEnable => 'Enable Now';

  @override
  String get biometricEnrollLater => 'Later';

  @override
  String get biometricSettingsQuickLogin => 'Quick Biometric Sign-in';

  @override
  String get biometricSettingsQuickLoginDesc =>
      'Use Face ID or Fingerprint to sign in instantly without typing password.';
}
