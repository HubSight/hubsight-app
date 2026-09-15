// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'HubSight';

  @override
  String get languageSelector => 'VN Tiếng Việt';

  @override
  String get languageBadge => 'VN VI';

  @override
  String get loginSubtitle => 'Đăng nhập để quản lý thiết bị và xem lại';

  @override
  String get usernameLabel => 'TÊN ĐĂNG NHẬP';

  @override
  String get usernameHint => 'admin';

  @override
  String get passwordLabel => 'MẬT KHẨU';

  @override
  String get passwordHint => '••••••••••••';

  @override
  String get loginButton => 'Đăng nhập';

  @override
  String get footerVersion => 'HubSight v1.0.0+sha-91d8e0d.';

  @override
  String get footerCopyright => '© 2026 by Anh Quoc Tran';

  @override
  String get dashboardTitle => 'Bảng điều khiển trực tiếp HubSight';

  @override
  String get dashboardNoCameras => 'Không tìm thấy camera nào';

  @override
  String get cameraOffline => 'Camera ngoại tuyến';

  @override
  String get cameraOnline => 'Đang hoạt động (Online)';

  @override
  String get cameraStopped => 'Đã tắt / Ngoại tuyến';

  @override
  String get selectCamera => 'Chọn camera';

  @override
  String get deviceLabel => 'Thiết bị:';

  @override
  String get dateLabel => 'Ngày:';

  @override
  String get recordsLabel => 'Bản ghi:';

  @override
  String get noData => 'Không có dữ liệu';

  @override
  String get loading => 'Đang tải...';

  @override
  String recordsCount(Object count) {
    return '$count bản ghi';
  }

  @override
  String get eventTimelineTitle =>
      'Dòng thời gian sự kiện (Event-based Playback)';

  @override
  String get noEventsToday => 'Không có sự kiện bất thường nào trong ngày này';

  @override
  String eventsToday(Object count) {
    return 'Có $count sự kiện được ghi lại';
  }

  @override
  String filterAll(Object count) {
    return 'Tất cả ($count)';
  }

  @override
  String get filterMorning => '00-12h';

  @override
  String get filterAfternoon => '12-18h';

  @override
  String get filterEvening => '18-24h';

  @override
  String get live => 'TRỰC TIẾP';

  @override
  String get cameraStoppedStatus => 'ĐÃ TẮT';

  @override
  String cameraStoppedTitle(Object camera) {
    return '“$camera” đã tắt';
  }

  @override
  String get cameraStoppedDesc =>
      'Luồng trực tiếp đang ngoại tuyến. Chọn camera khác từ danh sách, hoặc chờ admin bật lại.';

  @override
  String get notificationTitle => 'Thông báo';

  @override
  String get notificationSubtitle => 'Lịch sử nhận diện người và cảnh báo';

  @override
  String filterUnread(Object count) {
    return 'Chưa đọc ($count)';
  }

  @override
  String get deleteAll => 'Xoá tất cả';

  @override
  String get viewPlayback => 'Xem lại camera';

  @override
  String get noNotifications => 'Không có thông báo nào';

  @override
  String get confirmDeleteAll =>
      'Bạn có chắc chắn muốn xoá tất cả thông báo không?';

  @override
  String get confirmDelete => 'Xoá';

  @override
  String get cancel => 'Huỷ';

  @override
  String get menuHome => 'Trang chủ';

  @override
  String get menuDevices => 'Thiết bị';

  @override
  String get menuMembers => 'Thành viên';

  @override
  String get menuPlayback => 'Xem lại';

  @override
  String get tabPlayback => 'Xem lại';

  @override
  String get tabDashboard => 'Lưới Camera';

  @override
  String get tabNotifications => 'Thông báo';

  @override
  String get tabSettings => 'Cài đặt';

  @override
  String get menuNvrMonitor => 'Giám sát NVR';

  @override
  String get menuConnectionPool => 'Connection Pool';

  @override
  String get menuLanguage => 'Ngôn ngữ';

  @override
  String get sidebarSubtitle => 'Giám sát trực tiếp';

  @override
  String get adminRole => 'QUẢN TRỊ';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get settingsTitle => 'Cài đặt thiết bị & Bảo mật';

  @override
  String get settingsSubtitle =>
      'Tuỳ chỉnh thông báo, múi giờ và khoá bảo mật ứng dụng';

  @override
  String get appModeTitle => 'Chế độ Trình Duyệt Web';

  @override
  String get appModeDesc =>
      'Cài đặt ứng dụng dưới dạng ứng dụng độc lập để có trải nghiệm khoá ứng dụng mượt mà nhất.';

  @override
  String get timezoneTitle => 'Múi giờ hiển thị';

  @override
  String get timezoneDesc =>
      'Múi giờ dùng để hiển thị thời gian trong các thông báo và nhật ký (Mặc định: UTC+7).';

  @override
  String get selectTimezone => 'Chọn múi giờ';

  @override
  String get pushSettingsTitle => 'Cài đặt thông báo đẩy (Push)';

  @override
  String get pushSettingsSubtitle =>
      'Chọn phân loại sự kiện bạn muốn nhận push';

  @override
  String get pushFamily => 'Người quen (Gia đình, Khách)';

  @override
  String get pushFamilyDesc =>
      'Thông báo khi camera nhận diện được thành viên gia đình hoặc khách quen.';

  @override
  String get pushStranger => 'Cảnh báo an ninh & Người lạ';

  @override
  String get pushStrangerDesc =>
      'Bao gồm người lạ mặt, đột nhập, té ngã, vũ khí, cháy nổ...';

  @override
  String get pushSystem => 'Thông báo hệ thống';

  @override
  String get pushSystemDesc =>
      'Cảnh báo tình trạng hệ thống NVR, lỗi kết nối hoặc lưu trữ đầy.';

  @override
  String get lockOnBackground => 'Khoá khi chạy nền';

  @override
  String get lockOnBackgroundDesc =>
      'Tự động khoá màn hình khi ứng dụng bị ẩn hoặc thu nhỏ.';

  @override
  String get biometricUnlock => 'Mở khoá sinh trắc học (Face ID / Vân tay)';

  @override
  String get biometricUnlockDesc =>
      'Sử dụng cảm biến sinh trắc học WebAuthn hoặc mã PIN thiết bị để mở khoá nhanh.';

  @override
  String get lockTimeoutTitle => 'Thời gian chờ khoá màn hình';

  @override
  String get lockTimeoutDesc =>
      'Chọn khoảng thời gian ứng dụng chạy nền trước khi tự động khoá.';

  @override
  String get timeoutImmediately => 'Ngay lập tức';

  @override
  String get timeout1Min => '1 Phút';

  @override
  String get timeout5Mins => '5 Phút';

  @override
  String get changePasswordTitle => 'Đổi mật khẩu';

  @override
  String get changePasswordSubtitle => 'Cập nhật mật khẩu tài khoản';

  @override
  String get currentPassword => 'Mật khẩu hiện tại';

  @override
  String get currentPasswordPlaceholder => 'Nhập mật khẩu hiện tại';

  @override
  String get newPassword => 'Mật khẩu mới';

  @override
  String get newPasswordPlaceholder => 'Tối thiểu 6 ký tự';

  @override
  String get confirmNewPassword => 'Xác nhận mật khẩu mới';

  @override
  String get confirmNewPasswordPlaceholder => 'Nhập lại mật khẩu mới';

  @override
  String get savePassword => 'Lưu mật khẩu';

  @override
  String get passwordUpdated => 'Mật khẩu đã được cập nhật!';

  @override
  String get passwordMismatch => 'Xác nhận mật khẩu không khớp';

  @override
  String get passwordShort => 'Mật khẩu mới phải có ít nhất 6 ký tự';

  @override
  String get timeJustNow => 'Vừa xong';

  @override
  String timeMinutesAgo(Object count) {
    return '$count phút trước';
  }

  @override
  String timeHoursAgo(Object count) {
    return '$count giờ trước';
  }

  @override
  String timeDaysAgo(Object count) {
    return '$count ngày trước';
  }

  @override
  String timeMonthsAgo(Object count) {
    return '$count tháng trước';
  }

  @override
  String get playingArchive => 'Đang phát lại bản ghi';

  @override
  String recordingEvent(Object type) {
    return 'Sự kiện: $type';
  }

  @override
  String get serverConfigTitle => 'Cấu hình Máy chủ';

  @override
  String get serverConfigSubtitle =>
      'Nhập địa chỉ máy chủ API Gateway để kết nối với hệ thống HubSight.';

  @override
  String get serverUrlLabel => 'ĐỊA CHỈ MÁY CHỦ (SERVER URL)';

  @override
  String get serverUrlHint => 'http://10.0.2.2:8088';

  @override
  String get serverUrlHelp =>
      'Ví dụ: http://192.168.1.100:8088 hoặc https://cctv.yourdomain.com';

  @override
  String get testConnection => 'Kiểm tra kết nối';

  @override
  String get connectionSuccess => 'Kết nối tới máy chủ thành công!';

  @override
  String get connectionFailed =>
      'Không thể kết nối tới máy chủ. Vui lòng kiểm tra lại URL.';

  @override
  String get continueButton => 'Tiếp tục';

  @override
  String get serverUrlEmpty => 'Vui lòng nhập địa chỉ máy chủ';

  @override
  String get serverUrlInvalid =>
      'Địa chỉ máy chủ không hợp lệ (phải bắt đầu bằng http:// hoặc https://)';

  @override
  String get changeServer => 'Đổi máy chủ';

  @override
  String get serverConfigSetting => 'Cấu hình địa chỉ máy chủ';

  @override
  String get enrollHscfgTitle => 'Đăng ký thiết bị (.hscfg)';

  @override
  String get enrollHscfgDesc =>
      'Chọn tệp cấu hình bảo mật .hscfg do Quản trị viên cấp và nhập mã PIN 6 số để tự động thiết lập.';

  @override
  String get pickHscfgFile => 'Chọn tệp .hscfg';

  @override
  String fileSelected(Object filename) {
    return 'Đã chọn: $filename';
  }

  @override
  String get pinLabel => 'MÃ PIN BẢO MẬT (6 SỐ)';

  @override
  String get pinHint => 'Nhập mã PIN (VD: 123456)';

  @override
  String get enrollButton => 'Giải mã & Kết nối';

  @override
  String get orManualSetup => 'HOẶC THIẾT LẬP THỦ CÔNG';

  @override
  String get apiKeyLabel => 'CLIENT API KEY';

  @override
  String get apiKeyHint => 'X-API-Key (VD: hsc_live_app_...)';

  @override
  String get twoFactorTitle => 'Xác thực hai bước (2FA)';

  @override
  String get twoFactorSubtitle =>
      'Nhập mã TOTP 6 số từ ứng dụng Google Authenticator của bạn.';

  @override
  String get twoFactorCodeLabel => 'MÃ XÁC THỰC (6 CHỮ SỐ)';

  @override
  String get twoFactorCodeHint => 'VD: 123456';

  @override
  String get useRecoveryCode => 'Dùng mã khôi phục dự phòng';

  @override
  String get recoveryCodeLabel => 'MÃ KHÔI PHỤC DỰ PHÒNG';

  @override
  String get verifyButton => 'Xác nhận & Đăng nhập';

  @override
  String get twoFactorFailed =>
      'Mã xác thực 2FA không chính xác hoặc đã hết hạn';

  @override
  String get sessionsTitle => 'Thiết bị & Phiên hoạt động';

  @override
  String get sessionsSubtitle =>
      'Quản lý và thu hồi phiên đăng nhập trên các thiết bị khác';

  @override
  String get currentSession => 'Phiên này';

  @override
  String get revokeSession => 'Thu hồi';

  @override
  String get confirmRevokeSession =>
      'Bạn có chắc chắn muốn thu hồi phiên đăng nhập này? Thiết bị đó sẽ bị ngắt kết nối ngay lập tức.';

  @override
  String get sessionRevokedSuccess => 'Đã thu hồi phiên đăng nhập thành công';

  @override
  String get remoteRevokedAlert =>
      'Phiên đăng nhập của bạn đã bị thu hồi từ xa bởi Quản trị viên hoặc thiết bị khác.';

  @override
  String get maintenanceTitle => 'Bảo trì Hệ thống';

  @override
  String get maintenanceMessage =>
      'Dịch vụ kết nối ứng dụng di động hiện đang tạm dừng để bảo trì hệ thống.';

  @override
  String retryAfterCountdown(Object seconds) {
    return 'Tự động thử lại sau: $seconds giây';
  }

  @override
  String get retryNow => 'Thử lại ngay';

  @override
  String get multiViewTitle => 'Xem lưới đa kênh (Multi-View)';

  @override
  String get multiViewDesc => 'Đàm phán WebRTC song song và tối ưu hóa pin';

  @override
  String get switchLayout => 'Đổi bố cục';

  @override
  String get cameraStoppedPlaceholder => 'Camera tạm dừng';

  @override
  String get liveStreamLoading => 'Đang kết nối luồng trực tiếp...';

  @override
  String get mustChangePasswordTitle => 'Yêu cầu đổi mật khẩu';

  @override
  String get mustChangePasswordDesc =>
      'Tài khoản của bạn được yêu cầu đổi mật khẩu trước khi tiếp tục.';

  @override
  String get errConfigInvalidPin => 'Mã PIN phải bao gồm đúng 6 chữ số.';

  @override
  String get errConfigDecryptionFailed =>
      'Giải mã tệp cấu hình thất bại. Mã PIN không đúng hoặc tệp bị hỏng.';

  @override
  String get errConfigInvalidSignature =>
      'Chữ ký số Ed25519 của tệp cấu hình không hợp lệ.';

  @override
  String get errAuthInvalidCredentials =>
      'Tên đăng nhập hoặc mật khẩu không chính xác.';

  @override
  String get errNetworkTimeout =>
      'Hết thời gian chờ kết nối máy chủ. Vui lòng kiểm tra lại mạng.';

  @override
  String get errNetworkUnreachable =>
      'Không thể kết nối đến máy chủ API Gateway.';

  @override
  String get errSessionExpired =>
      'Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại.';

  @override
  String get errAppKeyRequired =>
      'Ứng dụng chưa được cấu hình API Key. Vui lòng quét mã QR hoặc cấu hình tệp .hscfg.';

  @override
  String get errAppKeyInvalid =>
      'API Key của ứng dụng không hợp lệ hoặc đã bị thu hồi. Vui lòng cấu hình lại.';

  @override
  String get errGeneric => 'Đã có lỗi xảy ra. Vui lòng thử lại sau.';

  @override
  String get scanQrTabTitle => 'Quét mã QR';

  @override
  String get scanQrDesc =>
      'Hướng máy ảnh về mã QR cấu hình HubSight do Quản trị viên cấp.';

  @override
  String get scanQrPickImage => 'Chọn ảnh QR từ thư viện';

  @override
  String get scanQrInvalidPayload =>
      'Mã QR không hợp lệ hoặc không phải định dạng HubSight.';

  @override
  String get scanQrDownloading => 'Đang tải tệp cấu hình...';

  @override
  String get scanQrChecksumMismatch =>
      'Mã băm SHA-256 của tệp cấu hình không hợp lệ.';

  @override
  String get scanQrEnterPinPrompt => 'Nhập mã PIN 6 số để mở khóa cấu hình';

  @override
  String scanQrConfigIdentified(Object name) {
    return 'Đã nhận diện: $name';
  }

  @override
  String get cameraPermissionRequired =>
      'Ứng dụng cần quyền truy cập máy ảnh để quét mã QR.';

  @override
  String get tabHscfgFile => 'Tệp cấu hình (.hscfg)';

  @override
  String get loginOrDivider => 'HOẶC';

  @override
  String get loginPasskeyBtn => 'Đăng nhập bằng Passkey';

  @override
  String get loginPasskeyUsernameRequired =>
      'Nhập tên đăng nhập trước khi đăng nhập bằng Passkey.';

  @override
  String get loginPasskeyBtnFaceId => 'Đăng nhập bằng Face ID';

  @override
  String get loginPasskeyBtnTouchId => 'Đăng nhập bằng Touch ID';

  @override
  String get loginPasskeyBtnFingerprint => 'Đăng nhập bằng Vân tay';

  @override
  String get loginBiometricPrompt =>
      'Xác thực sinh trắc học để đăng nhập HubSight';

  @override
  String get loginBiometricNotConfigured =>
      'Chưa lưu thông tin sinh trắc học trên thiết bị này. Vui lòng đăng nhập bằng mật khẩu trước để kích hoạt.';

  @override
  String get loginBiometricNotEnrolled =>
      'Thiết bị chưa cài đặt vân tay hoặc Face ID trong Cài đặt máy.';

  @override
  String get loginBiometricNotSupported =>
      'Thiết bị không hỗ trợ hoặc chưa cài đặt sinh trắc học.';

  @override
  String get loginBiometricFailed =>
      'Xác thực sinh trắc học thất bại hoặc đã bị huỷ.';

  @override
  String get biometricEnrollPromptTitle => 'Kích hoạt sinh trắc học?';

  @override
  String get biometricEnrollPromptDesc =>
      'Bạn có muốn sử dụng sinh trắc học để đăng nhập nhanh vào HubSight cho những lần sau không?';

  @override
  String get biometricEnrollEnable => 'Kích hoạt ngay';

  @override
  String get biometricEnrollLater => 'Để sau';

  @override
  String get biometricSettingsQuickLogin =>
      'Đăng nhập nhanh bằng sinh trắc học';

  @override
  String get biometricSettingsQuickLoginDesc =>
      'Sử dụng Face ID hoặc Vân tay để đăng nhập ngay mà không cần nhập mật khẩu.';

  @override
  String get passkeyTitle => 'Khóa bảo mật & Sinh trắc học';

  @override
  String get passkeySubtitle =>
      'Đăng nhập nhanh không cần mật khẩu với Face ID, Touch ID, Windows Hello hoặc mã PIN thiết bị.';

  @override
  String get addPasskeyBtn => 'Thêm thiết bị';

  @override
  String get noPasskeys =>
      'Chưa có thiết bị xác thực nào được liên kết với tài khoản này.';

  @override
  String get passkeyCreated => 'Đã liên kết';

  @override
  String get passkeyLastUsed => 'Dùng lần cuối';

  @override
  String get passkeyNeverUsed => 'Chưa sử dụng';

  @override
  String get renamePasskey => 'Đổi tên';

  @override
  String get deletePasskey => 'Xóa';

  @override
  String get passkeyNamePlaceholder =>
      'Ví dụ: iPhone Face ID / MacBook Touch ID';

  @override
  String get passkeyNamePrompt => 'Đặt tên cho thiết bị xác thực:';

  @override
  String get confirmDeletePasskey =>
      'Bạn có chắc muốn xóa thiết bị xác thực này không?';

  @override
  String get passkeyUpdated => 'Đã cập nhật tên thiết bị!';

  @override
  String get passkeyDeleted => 'Đã xóa thiết bị xác thực!';

  @override
  String get passkeyAdded => 'Đã thêm thiết bị xác thực thành công!';

  @override
  String get passkeyEnrollDialogTitle => 'Thêm thiết bị xác thực mới';

  @override
  String get themeTitle => 'Giao diện hiển thị';

  @override
  String get themeSubtitle =>
      'Tùy chỉnh chế độ hiển thị sáng, tối hoặc tự động theo thiết bị';

  @override
  String get themeSystem => 'Theo thiết bị';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get themeSystemDesc => 'Tự động đồng bộ theo hệ thống';

  @override
  String get themeLightDesc => 'Tối ưu cho môi trường nhiều ánh sáng';

  @override
  String get themeDarkDesc => 'Dịu mắt, tiết kiệm pin cho màn hình OLED';

  @override
  String get ptzControl => 'Điều khiển PTZ';

  @override
  String get ptzPadTitle => 'Điều khiển Xoay / Thu phóng PTZ';

  @override
  String get onvifBadge => 'ONVIF';

  @override
  String get ptzBadge => 'PTZ';

  @override
  String get onvifDiscovery => 'Dò tìm thiết bị ONVIF';

  @override
  String get onvifDiscoverySubtitle =>
      'Quét thông tin camera mạng, firmware, cấu hình & PTZ';

  @override
  String get probeCamera => 'Quét thiết bị';

  @override
  String get probeHost => 'Địa chỉ IP / Host';

  @override
  String get probePort => 'Cổng ONVIF';

  @override
  String get probeUsername => 'Tài khoản ONVIF';

  @override
  String get probePassword => 'Mật khẩu ONVIF';

  @override
  String get probeSuccess => 'Dò tìm ONVIF thành công';

  @override
  String get probeFailed => 'Dò tìm ONVIF thất bại';

  @override
  String get presetsTitle => 'Điểm nhớ vị trí';

  @override
  String get addPreset => 'Lưu góc hiện tại';

  @override
  String get presetNamePrompt => 'Nhập tên điểm nhớ vị trí:';

  @override
  String get biometricFingerprint => 'Vân tay';

  @override
  String get biometricIris => 'Mống mắt';

  @override
  String get biometricGeneral => 'Sinh trắc học';

  @override
  String get biometricDefaultReason => 'Vui lòng xác thực để mở khóa HubSight';

  @override
  String lockBiometricReason(Object biometric) {
    return 'Xác thực $biometric để mở khóa HubSight';
  }

  @override
  String get lockPinMismatch => 'Mã PIN xác nhận không khớp. Vui lòng thử lại.';

  @override
  String lockNoPinPrompt(Object biometric) {
    return 'Chưa có mã PIN. Vui lòng mở khóa bằng $biometric';
  }

  @override
  String get lockPinIncorrect => 'Mã PIN không chính xác';

  @override
  String get lockEnterPin => 'Nhập mã PIN để mở khóa';

  @override
  String get lockConfirmPin => 'Xác nhận lại mã PIN';

  @override
  String get lockSetNewPin => 'Thiết lập mã PIN mới';

  @override
  String lockEnterPinOrBiometric(Object biometric) {
    return 'Nhập PIN hoặc dùng $biometric';
  }

  @override
  String get lockLogoutAccount => 'Đăng xuất khỏi tài khoản';

  @override
  String loginQuickBiometricReason(Object biometric) {
    return 'Đăng nhập nhanh bằng $biometric vào HubSight';
  }

  @override
  String get serverNotConfigured => 'Chưa cấu hình máy chủ';

  @override
  String get configureServerNow => 'Cấu hình máy chủ ngay';

  @override
  String get recoveryCodeHint => 'Nhập mã khôi phục 8-16 ký tự';

  @override
  String get useTotpCode => 'Sử dụng mã xác thực 6 số';

  @override
  String get backToLogin => 'Quay lại đăng nhập';

  @override
  String get onvifModeSystemCameras => 'Camera trong hệ thống';

  @override
  String get onvifModeCustomIp => 'Nhập IP tùy chỉnh';

  @override
  String get onvifHostHint => '192.168.1.100 hoặc hostname';

  @override
  String get onvifPasswordHint => 'Mật khẩu ONVIF (nếu có)';

  @override
  String get probingCamera => 'Đang dò tìm...';

  @override
  String get onvifPtzSupported => 'Hỗ trợ PTZ';

  @override
  String get onvifDeviceInfo => 'Thông tin thiết bị';

  @override
  String get onvifManufacturer => 'Nhà sản xuất';

  @override
  String get onvifModel => 'Mẫu mã (Model)';

  @override
  String get onvifFirmwareVersion => 'Phiên bản Firmware';

  @override
  String get onvifSerialNumber => 'Số Serial';

  @override
  String get onvifMediaProfiles => 'Cấu hình luồng (Media Profiles)';

  @override
  String get onvifNoProfiles => 'Chưa trích xuất được profile media.';

  @override
  String get onvifRtspCopied => 'Đã sao chép RTSP Stream URI!';

  @override
  String aiAlertNotification(Object camera, Object event) {
    return 'Cảnh báo AI: $event tại camera $camera';
  }

  @override
  String get allCameras => 'Tất cả';

  @override
  String get recentRecognitions => 'Nhật ký nhận diện gần đây';

  @override
  String eventsCount(Object count) {
    return '$count sự kiện';
  }

  @override
  String get noRecognitionData => 'Chưa có dữ liệu nhận diện khuôn mặt';

  @override
  String get stranger => 'Người lạ';

  @override
  String get noActiveStreamingCameras =>
      'Không có camera nào đang hoạt động để phát trực tiếp';

  @override
  String get ptzPresetHint => 'e.g. Cổng chính, Cửa sổ, Sân sau';

  @override
  String ptzPresetSaved(Object name) {
    return 'Đã lưu điểm nhớ: $name';
  }

  @override
  String ptzPresetSaveFailed(Object error) {
    return 'Không thể lưu điểm nhớ: $error';
  }

  @override
  String get ptzDeletePresetTitle => 'Xóa điểm nhớ';

  @override
  String ptzDeletePresetConfirm(Object name) {
    return 'Bạn có chắc chắn muốn xóa điểm nhớ \"$name\" không?';
  }

  @override
  String ptzPresetDeleted(Object name) {
    return 'Đã xóa điểm nhớ: $name';
  }

  @override
  String ptzPresetDeleteFailed(Object error) {
    return 'Lỗi xóa điểm nhớ: $error';
  }

  @override
  String ptzCommandFailed(Object error) {
    return 'Lệnh PTZ không thành công: $error';
  }

  @override
  String get ptzHoldInstruction =>
      'Nhấn giữ nút mũi tên để quay quét camera, thả tay để dừng.';

  @override
  String get ptzNoPresets => 'Chưa có điểm nhớ nào được lưu cho camera này.';

  @override
  String ptzMovingTo(Object name) {
    return 'Đang xoay camera tới: $name';
  }

  @override
  String ptzMoveFailed(Object error) {
    return 'Lỗi chuyển vị trí: $error';
  }

  @override
  String get webrtcErrBadGateway =>
      'Máy chủ hoặc kết nối camera đang tạm thời gián đoạn (502 Bad Gateway). Đang thử lại...';

  @override
  String get webrtcErrNotFound =>
      'Camera không tồn tại hoặc đã bị gỡ khỏi hệ thống.';

  @override
  String get webrtcErrUnauthorized =>
      'Phiên đăng nhập đã hết hạn hoặc không có quyền xem camera này.';

  @override
  String get webrtcErrNetwork =>
      'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại kết nối mạng.';

  @override
  String webrtcErrConnection(Object error) {
    return 'Lỗi kết nối camera: $error';
  }

  @override
  String webrtcReconnecting(Object count, Object max) {
    return 'Đang tự động kết nối lại luồng video ($count/$max)...';
  }

  @override
  String get webrtcErrSdkNotReady => 'SDK chưa được khởi tạo';

  @override
  String get webrtcErrStreamFailed => 'Không thể kết nối luồng trực tiếp.';

  @override
  String fallAlertWarning(Object count) {
    return 'CẢNH BÁO: TÉ NGÃ ($count)';
  }

  @override
  String get webrtcConnecting => 'Đang kết nối WebRTC (WHEP)...';

  @override
  String get webrtcStreamUnavailable => 'Luồng trực tiếp không khả dụng';

  @override
  String get retryButton => 'Thử lại';

  @override
  String get markAllRead => 'Đã đọc hết';

  @override
  String get noUnreadNotifications => 'Không có thông báo chưa đọc';

  @override
  String get noUnreadNotificationsDesc =>
      'Bạn đã xem tất cả các cảnh báo an ninh';

  @override
  String get noNotificationsDesc =>
      'Các cảnh báo an ninh và sự kiện AI sẽ hiển thị ở đây';

  @override
  String passkeyDefaultDeviceName(Object biometric) {
    return '$biometric trên thiết bị này';
  }

  @override
  String get securitySectionTitle => 'Bảo mật ứng dụng';

  @override
  String get noOtherSessions => 'Không có phiên nào khác đang hoạt động';

  @override
  String get thisDevice => 'Thiết bị này';

  @override
  String otherSessionsCount(Object count) {
    return '$count phiên đăng nhập khác';
  }

  @override
  String get tapToCollapse => 'Chạm để thu gọn';

  @override
  String get tapToManageAndRevoke => 'Chạm để quản lý và thu hồi';

  @override
  String get genericDevice => 'Thiết bị';

  @override
  String get changePinTitle => 'Đổi mã PIN bảo mật';

  @override
  String get changePinSubtitle => 'Thiết lập lại mã PIN 4 chữ số dự phòng';

  @override
  String get pinUpdatedSuccess => 'Đã cập nhật mã PIN mới thành công';

  @override
  String get notConfigured => 'Chưa cấu hình';

  @override
  String serverProfileActive(Object name) {
    return 'Profile: $name • Đang hoạt động';
  }

  @override
  String get gatewayNotConnected => 'Chưa kết nối cổng Gateway';

  @override
  String get confirmLogout =>
      'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này?';

  @override
  String configPickFileError(Object error) {
    return 'Không thể chọn tệp tin: $error';
  }

  @override
  String configQrAnalyzeError(Object error) {
    return 'Lỗi phân tích hình ảnh QR: $error';
  }

  @override
  String get configNoDataFromServer =>
      'Không có dữ liệu trả về từ máy chủ cấu hình.';

  @override
  String get configNoFileSelectedError =>
      'Chưa có tệp tin cấu hình. Vui lòng quay lại bước trước.';

  @override
  String get configDecryptingSignature =>
      'Đang giải mã và kiểm tra chữ ký số...';

  @override
  String get configSavingSystem => 'Đang lưu cấu hình hệ thống...';

  @override
  String get configSuccessLoginPrompt =>
      'Cấu hình máy chủ thành công! Vui lòng đăng nhập.';

  @override
  String configSaveError(Object error) {
    return 'Lỗi lưu cấu hình: $error';
  }

  @override
  String get configStepWelcome => 'Thiết lập HubSight';

  @override
  String get configStepMethod => 'Phương thức kết nối';

  @override
  String get configStepPickFile => 'Chọn tệp cấu hình';

  @override
  String get configStepScanQr => 'Quét mã QR';

  @override
  String get configStepPin => 'Mã PIN bảo mật';

  @override
  String get configStepSummary => 'Xác nhận cấu hình';

  @override
  String get processing => 'Đang xử lý...';

  @override
  String get configWelcomeTitle => 'Chào mừng đến với HubSight';

  @override
  String get configWelcomeSubtitle =>
      'Để kết nối ứng dụng với máy chủ giám sát của bạn, vui lòng nhập tệp cấu hình bảo mật (.hscfg) hoặc quét mã QR do quản trị viên cấp.';

  @override
  String get configFeatureE2eeTitle => 'Mã hoá đa tầng End-to-End';

  @override
  String get configFeatureE2eeDesc =>
      'Bảo vệ bằng thuật toán Argon2id và mã hoá AES-256-GCM quân sự.';

  @override
  String get configFeatureEd25519Title => 'Xác thực chữ ký số Ed25519';

  @override
  String get configFeatureEd25519Desc =>
      'Đảm bảo tệp tin nguyên bản, chống giả mạo hoặc can thiệp máy chủ.';

  @override
  String get configFeatureZeroConfigTitle => 'Zero-Config Setup';

  @override
  String get configFeatureZeroConfigDesc =>
      'Tự động thiết lập Gateway, WebSocket Relay và WebRTC trong vài giây.';

  @override
  String get configStartSetup => 'Bắt đầu thiết lập';

  @override
  String get configSelectMethodTitle => 'Chọn phương thức kết nối';

  @override
  String get configSelectMethodDesc =>
      'Lựa chọn cách thức thuận tiện nhất để nhập thông số kết nối vào ứng dụng:';

  @override
  String get configMethodQrTitle => 'Quét mã QR cấu hình';

  @override
  String get configMethodQrDesc =>
      'Sử dụng camera thiết bị để quét mã QR cấu hình trực tiếp từ màn hình máy tính hoặc ảnh lưu trữ.';

  @override
  String get configMethodRecommended => 'Khuyên dùng';

  @override
  String get configMethodFileTitle => 'Chọn tệp cấu hình (.hscfg)';

  @override
  String get configMethodFileDesc =>
      'Chọn tệp tin container bảo mật (.hscfg) đã được tải về trên thiết bị của bạn.';

  @override
  String get backButton => 'Quay lại';

  @override
  String get configPickFileTitle => 'Chọn tệp cấu hình (.hscfg)';

  @override
  String get configPickFileSubtitle =>
      'Chọn tệp container an toàn được quản trị viên xuất từ hệ thống.';

  @override
  String get configTapToPickFile => 'Nhấn để chọn tệp .hscfg';

  @override
  String configFileSizeKb(Object size) {
    return 'Dung lượng: $size KB';
  }

  @override
  String get configStandardFormatSupport =>
      'Hỗ trợ định dạng .hscfg tiêu chuẩn';

  @override
  String get configReadyToDecrypt => 'SẴN SÀNG GIẢI MÃ';

  @override
  String get configPickAnotherFile => 'Chọn tệp khác';

  @override
  String get configQrInstruction =>
      'Hướng camera vào mã QR cấu hình để tự động nhận dạng';

  @override
  String get configFlashTooltip => 'Đèn flash';

  @override
  String get configQrPickGallery => 'Chọn ảnh QR từ thư viện';

  @override
  String get configSwitchCameraTooltip => 'Đổi camera';

  @override
  String get configQrFallbackName => 'Mã QR';

  @override
  String get configEnterPinTitle => 'Nhập mã PIN bảo mật (6 số)';

  @override
  String get configEnterPinSubtitle =>
      'Nhập mã PIN 6 số do quản trị viên cấp để giải nén và giải mã container dữ liệu.';

  @override
  String get configDecryptButton => 'Giải nén & Giải mã';

  @override
  String get configDecryptionSuccess => 'Giải mã & Xác thực thành công';

  @override
  String get configSignatureValid =>
      'Chữ ký số Ed25519 hợp lệ. Tệp tin nguyên bản.';

  @override
  String get configConfirmTitle => 'Xác nhận thông tin cấu hình';

  @override
  String get configConfirmSubtitle =>
      'Kiểm tra kỹ các thông số kết nối trước khi lưu cấu hình và kích hoạt ứng dụng:';

  @override
  String get configSummarySystemName => 'Tên hệ thống';

  @override
  String get configSummaryConfigId => 'Mã cấu hình';

  @override
  String get configSummaryGateway => 'Máy chủ Gateway';

  @override
  String get configSummaryClientName => 'Tên máy khách';

  @override
  String get configSummaryCreatedBy => 'Tạo bởi';

  @override
  String get configSummaryCreatedAt => 'Thời gian tạo';

  @override
  String get none => 'Không có';

  @override
  String get configSummaryProfileVersion => 'Phiên bản hồ sơ';

  @override
  String get configConfirmAndProceed => 'Đồng ý & Chuyển sang Đăng nhập';

  @override
  String get configResetFromScratch => 'Thiết lập lại từ đầu';

  @override
  String get splashTagline => 'Giám sát & Quản trị Camera Thông minh';

  @override
  String get splashSubtitle => 'Nền tảng Camera An ninh & AI Doanh nghiệp';

  @override
  String get splashInitializing => 'Đang khởi tạo môi trường bảo mật...';

  @override
  String get liveTab => 'Trực tiếp';

  @override
  String get playbackTab => 'Xem lại';

  @override
  String get ptzControlPanel => 'Điều khiển PTZ';

  @override
  String get ptzSwipeHint => 'Vuốt trên video để xoay camera';

  @override
  String get ptzQuickAction => 'Điều khiển PTZ';
}
