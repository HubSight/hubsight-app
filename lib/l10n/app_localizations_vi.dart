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
  String get loginPasskeyBtn => 'Đăng nhập bằng Vân tay / Face ID';

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
}
