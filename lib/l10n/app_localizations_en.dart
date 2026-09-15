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
  String get tabPlayback => 'Playback';

  @override
  String get tabDashboard => 'Live Grid';

  @override
  String get tabNotifications => 'Notifications';

  @override
  String get tabSettings => 'Settings';

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
  String get loginPasskeyBtn => 'Sign in with Passkey';

  @override
  String get loginPasskeyUsernameRequired =>
      'Enter your username before signing in with a Passkey.';

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

  @override
  String get passkeyTitle => 'Biometric & Security Keys';

  @override
  String get passkeySubtitle =>
      'Fast passwordless sign-in with Face ID, Touch ID, Windows Hello or Device PIN.';

  @override
  String get addPasskeyBtn => 'Add Device';

  @override
  String get noPasskeys =>
      'No authenticator devices registered on this account yet.';

  @override
  String get passkeyCreated => 'Linked';

  @override
  String get passkeyLastUsed => 'Last used';

  @override
  String get passkeyNeverUsed => 'Never';

  @override
  String get renamePasskey => 'Rename';

  @override
  String get deletePasskey => 'Remove';

  @override
  String get passkeyNamePlaceholder => 'e.g. iPhone Face ID / MacBook Touch ID';

  @override
  String get passkeyNamePrompt => 'Enter a label for this device:';

  @override
  String get confirmDeletePasskey =>
      'Are you sure you want to remove this authenticator device?';

  @override
  String get passkeyUpdated => 'Device updated successfully!';

  @override
  String get passkeyDeleted => 'Authenticator device removed!';

  @override
  String get passkeyAdded => 'Authenticator device registered successfully!';

  @override
  String get passkeyEnrollDialogTitle => 'Add New Authenticator Device';

  @override
  String get themeTitle => 'Theme Appearance';

  @override
  String get themeSubtitle =>
      'Customize light, dark or automatic system appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystemDesc => 'Automatically matches device setting';

  @override
  String get themeLightDesc => 'Optimized for well-lit environments';

  @override
  String get themeDarkDesc => 'Easy on the eyes and saves battery on OLED';

  @override
  String get ptzControl => 'PTZ Control';

  @override
  String get ptzPadTitle => 'Pan / Tilt / Zoom Control';

  @override
  String get onvifBadge => 'ONVIF';

  @override
  String get ptzBadge => 'PTZ';

  @override
  String get onvifDiscovery => 'ONVIF Discovery';

  @override
  String get onvifDiscoverySubtitle =>
      'Probe network cameras, firmware, profiles & PTZ';

  @override
  String get probeCamera => 'Probe Camera';

  @override
  String get probeHost => 'Host / IP Address';

  @override
  String get probePort => 'ONVIF Port';

  @override
  String get probeUsername => 'ONVIF Username';

  @override
  String get probePassword => 'ONVIF Password';

  @override
  String get probeSuccess => 'ONVIF probe successful';

  @override
  String get probeFailed => 'ONVIF probe failed';

  @override
  String get presetsTitle => 'Preset Positions';

  @override
  String get addPreset => 'Save Position';

  @override
  String get presetNamePrompt => 'Enter preset point name:';

  @override
  String get biometricFingerprint => 'Fingerprint';

  @override
  String get biometricIris => 'Iris';

  @override
  String get biometricGeneral => 'Biometrics';

  @override
  String get biometricDefaultReason => 'Please authenticate to unlock HubSight';

  @override
  String lockBiometricReason(Object biometric) {
    return 'Authenticate $biometric to unlock HubSight';
  }

  @override
  String get lockPinMismatch =>
      'Confirmation PIN does not match. Please try again.';

  @override
  String lockNoPinPrompt(Object biometric) {
    return 'No PIN set. Please unlock using $biometric';
  }

  @override
  String get lockPinIncorrect => 'Incorrect PIN code';

  @override
  String get lockEnterPin => 'Enter PIN code to unlock';

  @override
  String get lockConfirmPin => 'Re-enter PIN to confirm';

  @override
  String get lockSetNewPin => 'Set up new PIN code';

  @override
  String lockEnterPinOrBiometric(Object biometric) {
    return 'Enter PIN or use $biometric';
  }

  @override
  String get lockLogoutAccount => 'Logout of account';

  @override
  String loginQuickBiometricReason(Object biometric) {
    return 'Quick sign-in with $biometric to HubSight';
  }

  @override
  String get serverNotConfigured => 'Server not configured';

  @override
  String get configureServerNow => 'Configure server now';

  @override
  String get recoveryCodeHint => 'Enter 8-16 char recovery code';

  @override
  String get useTotpCode => 'Use 6-digit verification code';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get onvifModeSystemCameras => 'Cameras in system';

  @override
  String get onvifModeCustomIp => 'Custom IP/Host';

  @override
  String get onvifHostHint => '192.168.1.100 or hostname';

  @override
  String get onvifPasswordHint => 'ONVIF password (if any)';

  @override
  String get probingCamera => 'Probing...';

  @override
  String get onvifPtzSupported => 'PTZ Supported';

  @override
  String get onvifDeviceInfo => 'Device Information';

  @override
  String get onvifManufacturer => 'Manufacturer';

  @override
  String get onvifModel => 'Model';

  @override
  String get onvifFirmwareVersion => 'Firmware Version';

  @override
  String get onvifSerialNumber => 'Serial Number';

  @override
  String get onvifMediaProfiles => 'Media Profiles';

  @override
  String get onvifNoProfiles => 'Could not extract media profiles.';

  @override
  String get onvifRtspCopied => 'RTSP Stream URI copied to clipboard!';

  @override
  String aiAlertNotification(Object camera, Object event) {
    return 'AI Alert: $event at camera $camera';
  }

  @override
  String get allCameras => 'All';

  @override
  String get recentRecognitions => 'Recent Recognition Logs';

  @override
  String eventsCount(Object count) {
    return '$count events';
  }

  @override
  String get noRecognitionData => 'No facial recognition data available';

  @override
  String get stranger => 'Stranger';

  @override
  String get noActiveStreamingCameras =>
      'No active cameras available for live streaming';

  @override
  String get ptzPresetHint => 'e.g. Front Gate, Window, Backyard';

  @override
  String ptzPresetSaved(Object name) {
    return 'Preset saved: $name';
  }

  @override
  String ptzPresetSaveFailed(Object error) {
    return 'Failed to save preset: $error';
  }

  @override
  String get ptzDeletePresetTitle => 'Delete Preset';

  @override
  String ptzDeletePresetConfirm(Object name) {
    return 'Are you sure you want to delete preset \"$name\"?';
  }

  @override
  String ptzPresetDeleted(Object name) {
    return 'Preset deleted: $name';
  }

  @override
  String ptzPresetDeleteFailed(Object error) {
    return 'Failed to delete preset: $error';
  }

  @override
  String ptzCommandFailed(Object error) {
    return 'PTZ command failed: $error';
  }

  @override
  String get ptzHoldInstruction =>
      'Press and hold arrow buttons to pan/tilt camera, release to stop.';

  @override
  String get ptzNoPresets => 'No presets saved for this camera yet.';

  @override
  String ptzMovingTo(Object name) {
    return 'Moving camera to: $name';
  }

  @override
  String ptzMoveFailed(Object error) {
    return 'Failed to move camera: $error';
  }

  @override
  String get webrtcErrBadGateway =>
      'Server or camera connection temporarily disrupted (502 Bad Gateway). Retrying...';

  @override
  String get webrtcErrNotFound =>
      'Camera does not exist or has been removed from system.';

  @override
  String get webrtcErrUnauthorized =>
      'Session expired or you do not have permission to view this camera.';

  @override
  String get webrtcErrNetwork =>
      'Cannot connect to server. Please check your network connection.';

  @override
  String webrtcErrConnection(Object error) {
    return 'Camera connection error: $error';
  }

  @override
  String webrtcReconnecting(Object count, Object max) {
    return 'Reconnecting video stream automatically ($count/$max)...';
  }

  @override
  String get webrtcErrSdkNotReady => 'SDK has not been initialized';

  @override
  String get webrtcErrStreamFailed => 'Cannot connect to live stream.';

  @override
  String fallAlertWarning(Object count) {
    return 'WARNING: FALL DETECTED ($count)';
  }

  @override
  String get webrtcConnecting => 'Connecting WebRTC (WHEP)...';

  @override
  String get webrtcStreamUnavailable => 'Live stream unavailable';

  @override
  String get retryButton => 'Retry';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get noUnreadNotifications => 'No unread notifications';

  @override
  String get noUnreadNotificationsDesc =>
      'You have reviewed all security alerts';

  @override
  String get noNotificationsDesc =>
      'Security alerts and AI events will appear here';

  @override
  String passkeyDefaultDeviceName(Object biometric) {
    return '$biometric on this device';
  }

  @override
  String get securitySectionTitle => 'App Security';

  @override
  String get noOtherSessions => 'No other active sessions';

  @override
  String get thisDevice => 'This device';

  @override
  String otherSessionsCount(Object count) {
    return '$count other active sessions';
  }

  @override
  String get tapToCollapse => 'Tap to collapse';

  @override
  String get tapToManageAndRevoke => 'Tap to manage and revoke';

  @override
  String get genericDevice => 'Device';

  @override
  String get changePinTitle => 'Change Security PIN';

  @override
  String get changePinSubtitle => 'Reset your backup 4-digit PIN';

  @override
  String get pinUpdatedSuccess => 'New PIN code updated successfully';

  @override
  String get notConfigured => 'Not configured';

  @override
  String serverProfileActive(Object name) {
    return 'Profile: $name • Active';
  }

  @override
  String get gatewayNotConnected => 'Gateway port not connected';

  @override
  String get confirmLogout =>
      'Are you sure you want to log out of this account?';

  @override
  String configPickFileError(Object error) {
    return 'Could not select file: $error';
  }

  @override
  String configQrAnalyzeError(Object error) {
    return 'Error analyzing QR image: $error';
  }

  @override
  String get configNoDataFromServer =>
      'No data returned from configuration server.';

  @override
  String get configNoFileSelectedError =>
      'No configuration file selected. Please go back to the previous step.';

  @override
  String get configDecryptingSignature =>
      'Decrypting container and verifying digital signature...';

  @override
  String get configSavingSystem => 'Saving system configuration...';

  @override
  String get configSuccessLoginPrompt =>
      'Server configured successfully! Please log in.';

  @override
  String configSaveError(Object error) {
    return 'Error saving configuration: $error';
  }

  @override
  String get configStepWelcome => 'HubSight Setup';

  @override
  String get configStepMethod => 'Connection Method';

  @override
  String get configStepPickFile => 'Select Config File';

  @override
  String get configStepScanQr => 'Scan QR Code';

  @override
  String get configStepPin => 'Security PIN';

  @override
  String get configStepSummary => 'Confirm Configuration';

  @override
  String get processing => 'Processing...';

  @override
  String get configWelcomeTitle => 'Welcome to HubSight';

  @override
  String get configWelcomeSubtitle =>
      'To connect the app to your surveillance server, please import the secure configuration container (.hscfg) or scan the QR code provided by your administrator.';

  @override
  String get configFeatureE2eeTitle => 'Multi-layer End-to-End Encryption';

  @override
  String get configFeatureE2eeDesc =>
      'Protected by Argon2id key derivation and military-grade AES-256-GCM encryption.';

  @override
  String get configFeatureEd25519Title =>
      'Ed25519 Digital Signature Verification';

  @override
  String get configFeatureEd25519Desc =>
      'Guarantees container authenticity, preventing tampering or unauthorized server redirection.';

  @override
  String get configFeatureZeroConfigTitle => 'Zero-Config Setup';

  @override
  String get configFeatureZeroConfigDesc =>
      'Automatically configures Gateway, WebSocket Relay, and WebRTC in seconds.';

  @override
  String get configStartSetup => 'Start Setup';

  @override
  String get configSelectMethodTitle => 'Select Connection Method';

  @override
  String get configSelectMethodDesc =>
      'Choose the most convenient method to import connection parameters into the app:';

  @override
  String get configMethodQrTitle => 'Scan Configuration QR';

  @override
  String get configMethodQrDesc =>
      'Use device camera to scan configuration QR code directly from computer screen or saved photo.';

  @override
  String get configMethodRecommended => 'Recommended';

  @override
  String get configMethodFileTitle => 'Select Config File (.hscfg)';

  @override
  String get configMethodFileDesc =>
      'Select the secure container file (.hscfg) downloaded on your device.';

  @override
  String get backButton => 'Back';

  @override
  String get configPickFileTitle => 'Select Config File (.hscfg)';

  @override
  String get configPickFileSubtitle =>
      'Select the secure container file exported from the system by your administrator.';

  @override
  String get configTapToPickFile => 'Tap to select .hscfg file';

  @override
  String configFileSizeKb(Object size) {
    return 'File size: $size KB';
  }

  @override
  String get configStandardFormatSupport =>
      'Supports standard .hscfg container';

  @override
  String get configReadyToDecrypt => 'READY TO DECRYPT';

  @override
  String get configPickAnotherFile => 'Choose another file';

  @override
  String get configQrInstruction =>
      'Point camera at configuration QR code to scan automatically';

  @override
  String get configFlashTooltip => 'Flashlight';

  @override
  String get configQrPickGallery => 'Pick QR from gallery';

  @override
  String get configSwitchCameraTooltip => 'Switch camera';

  @override
  String get configQrFallbackName => 'QR Code';

  @override
  String get configEnterPinTitle => 'Enter Security PIN (6 digits)';

  @override
  String get configEnterPinSubtitle =>
      'Enter the 6-digit PIN provided by your administrator to unpack and decrypt data container.';

  @override
  String get configDecryptButton => 'Unpack & Decrypt';

  @override
  String get configDecryptionSuccess => 'Decryption & Verification Successful';

  @override
  String get configSignatureValid =>
      'Valid Ed25519 digital signature. Authentic file.';

  @override
  String get configConfirmTitle => 'Confirm Configuration Details';

  @override
  String get configConfirmSubtitle =>
      'Review connection parameters carefully before saving and activating application:';

  @override
  String get configSummarySystemName => 'System Name';

  @override
  String get configSummaryConfigId => 'Config ID';

  @override
  String get configSummaryGateway => 'Gateway Server';

  @override
  String get configSummaryClientName => 'Client Name';

  @override
  String get configSummaryCreatedBy => 'Created By';

  @override
  String get configSummaryCreatedAt => 'Created At';

  @override
  String get none => 'None';

  @override
  String get configSummaryProfileVersion => 'Profile Version';

  @override
  String get configConfirmAndProceed => 'Accept & Proceed to Login';

  @override
  String get configResetFromScratch => 'Reset from Beginning';

  @override
  String get splashTagline => 'Intelligent Video Surveillance & Management';

  @override
  String get splashSubtitle => 'Enterprise CCTV & AI Security Platform';

  @override
  String get splashInitializing => 'Initializing security environment...';

  @override
  String get liveTab => 'Live';

  @override
  String get playbackTab => 'Playback';

  @override
  String get ptzControlPanel => 'PTZ Controls';

  @override
  String get ptzSwipeHint => 'Swipe video to steer camera';

  @override
  String get ptzQuickAction => 'PTZ Control';
}
