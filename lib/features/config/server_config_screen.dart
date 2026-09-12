import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cctv_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/localization/error_localizer.dart';
import '../../core/network/sdk_provider.dart';
import '../auth/login_screen.dart';
import '../../core/theme/app_theme.dart';

class ServerConfigScreen extends ConsumerStatefulWidget {
  final bool isInitialSetup;

  const ServerConfigScreen({
    super.key,
    this.isInitialSetup = true,
  });

  @override
  ConsumerState<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends ConsumerState<ServerConfigScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // QR Scanner State
  late MobileScannerController _scannerController;
  bool _isProcessingQr = false;
  String? _qrError;

  // File Picker Enrollment State (.hscfg)
  Uint8List? _hscfgBytes;
  String? _hscfgFileName;
  final _filePinController = TextEditingController();
  bool _isEnrollingFile = false;
  String? _fileEnrollError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scannerController = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.normal,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController.dispose();
    _filePinController.dispose();
    super.dispose();
  }

  // ==========================================
  // QR Scanner Handlers
  // ==========================================

  void _onDetectBarcode(BarcodeCapture capture, AppLocalizations l10n) {
    if (_isProcessingQr) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;
    final raw = barcode.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    _handleQrScanned(raw.trim(), l10n);
  }

  Future<void> _handlePickQrImage(AppLocalizations l10n) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        final capture = await _scannerController.analyzeImage(result.files.first.path!);
        final raw = capture?.barcodes.firstOrNull?.rawValue;
        if (raw != null && raw.trim().isNotEmpty) {
          _handleQrScanned(raw.trim(), l10n);
        } else {
          setState(() {
            _qrError = l10n.scanQrInvalidPayload;
          });
        }
      }
    } catch (e) {
      setState(() {
        _qrError = 'Lỗi phân tích ảnh QR: $e';
      });
    }
  }

  void _handleQrScanned(String rawData, AppLocalizations l10n) {
    HubSightQRPayload payload;
    try {
      payload = HubSightQRPayload.fromString(rawData);
    } catch (_) {
      setState(() {
        _qrError = l10n.scanQrInvalidPayload;
      });
      return;
    }

    setState(() {
      _qrError = null;
      _isProcessingQr = true;
    });

    _showPinBottomSheet(payload, l10n);
  }

  void _showPinBottomSheet(HubSightQRPayload payload, AppLocalizations l10n) {
    final pinController = TextEditingController();
    String? modalError;
    bool isWorking = false;
    String statusMessage = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: HubSightColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: HubSightRadius.roundedSheet,
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final bottomInset = MediaQuery.of(modalContext).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: bottomInset + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: HubSightColors.borderDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0x2610B981),
                          borderRadius: HubSightRadius.roundedCard,
                          border: Border.all(color: const Color(0x4D10B981)),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          color: Color(0xFF10B981),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.scanQrConfigIdentified(
                                payload.name.isNotEmpty ? payload.name : payload.configId,
                              ),
                              style: const TextStyle(
                                color: HubSightColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'ID: ${payload.configId}',
                              style: const TextStyle(
                                color: HubSightColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Text(
                    l10n.scanQrEnterPinPrompt,
                    style: const TextStyle(
                      color: HubSightColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 6-digit PIN Field
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: true,
                    autofocus: true,
                    enabled: !isWorking,
                    style: const TextStyle(
                      color: HubSightColors.textPrimary,
                      fontSize: 22,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••••',
                      hintStyle: const TextStyle(
                        color: HubSightColors.textMuted,
                        letterSpacing: 8,
                      ),
                      filled: true,
                      fillColor: HubSightColors.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: HubSightRadius.roundedXl,
                        borderSide: const BorderSide(color: HubSightColors.borderDark),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: HubSightRadius.roundedXl,
                        borderSide: const BorderSide(color: HubSightColors.borderDark),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: HubSightRadius.roundedXl,
                        borderSide: const BorderSide(color: HubSightColors.primary, width: 1.5),
                      ),
                    ),
                  ),

                  if (statusMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: HubSightColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            statusMessage,
                            style: const TextStyle(
                              color: HubSightColors.textMuted,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (modalError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: HubSightColors.errorBg,
                        borderRadius: HubSightRadius.roundedXl,
                        border: Border.all(color: HubSightColors.errorBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: HubSightColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              modalError!,
                              style: const TextStyle(color: HubSightColors.errorText, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isWorking
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: HubSightColors.borderDark),
                            shape: RoundedRectangleBorder(
                              borderRadius: HubSightRadius.roundedXl,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            l10n.cancel,
                            style: const TextStyle(color: HubSightColors.textPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isWorking
                              ? null
                              : () async {
                                  final pin = pinController.text.trim();
                                  if (pin.length != 6 || int.tryParse(pin) == null) {
                                    setModalState(() {
                                      modalError = l10n.errConfigInvalidPin;
                                    });
                                    return;
                                  }

                                  setModalState(() {
                                    isWorking = true;
                                    modalError = null;
                                    statusMessage = l10n.scanQrDownloading;
                                  });

                                  try {
                                    // 1. Download container bytes
                                    final dio = Dio();
                                    final response = await dio.get<List<int>>(
                                      payload.downloadUrl,
                                      options: Options(
                                        responseType: ResponseType.bytes,
                                        connectTimeout: const Duration(seconds: 15),
                                        receiveTimeout: const Duration(seconds: 30),
                                      ),
                                    );

                                    if (response.data == null) {
                                      throw Exception('Không có dữ liệu trả về từ URL cấu hình.');
                                    }

                                    final downloadedBytes = Uint8List.fromList(response.data!);

                                    // 2. Validate SHA-256 Checksum if present
                                    if (payload.sha256.isNotEmpty) {
                                      final digest = sha256.convert(downloadedBytes).toString();
                                      if (digest.toLowerCase() != payload.sha256.toLowerCase()) {
                                        throw HubSightConfigException(
                                          code: HubSightErrorCode.configCorrupted,
                                          developerMessage: l10n.scanQrChecksumMismatch,
                                        );
                                      }
                                    }

                                    // 3. Decrypt & Enroll
                                    setModalState(() {
                                      statusMessage = 'Đang giải mã và kích hoạt thiết bị...';
                                    });

                                    await ref.read(hubsightSdkProvider.notifier).enrollFromHscfg(
                                          fileBytes: downloadedBytes,
                                          pin6Digits: pin,
                                        );

                                    if (modalContext.mounted) {
                                      Navigator.pop(modalContext);
                                    }
                                    if (mounted) {
                                      _navigateAfterSuccess();
                                    }
                                  } catch (e) {
                                    setModalState(() {
                                      isWorking = false;
                                      statusMessage = '';
                                      modalError = AppErrorLocalizer.localize(e, l10n);
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HubSightColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: HubSightRadius.roundedXl,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: isWorking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  l10n.enrollButton,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _isProcessingQr = false;
        });
      }
    });
  }

  // ==========================================
  // File Picker Handlers (.hscfg)
  // ==========================================

  Future<void> _handlePickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _hscfgBytes = file.bytes;
            _hscfgFileName = file.name;
            _fileEnrollError = null;
          });
        }
      }
    } catch (e) {
      setState(() => _fileEnrollError = 'Không thể chọn tệp: $e');
    }
  }

  Future<void> _handleEnrollHscfg(AppLocalizations l10n) async {
    final pin = _filePinController.text.trim();
    if (_hscfgBytes == null) {
      setState(() => _fileEnrollError = l10n.pickHscfgFile);
      return;
    }
    if (pin.length != 6 || int.tryParse(pin) == null) {
      setState(() => _fileEnrollError = l10n.errConfigInvalidPin);
      return;
    }

    setState(() {
      _isEnrollingFile = true;
      _fileEnrollError = null;
    });

    try {
      await ref.read(hubsightSdkProvider.notifier).enrollFromHscfg(
            fileBytes: _hscfgBytes!,
            pin6Digits: pin,
          );

      if (mounted) {
        _navigateAfterSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fileEnrollError = AppErrorLocalizer.localize(e, l10n);
        });
      }
    } finally {
      if (mounted) setState(() => _isEnrollingFile = false);
    }
  }

  void _navigateAfterSuccess() {
    if (widget.isInitialSetup) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cấu hình máy chủ thành công!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  // ==========================================
  // Build Methods
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: HubSightColors.bgDark,
      appBar: AppBar(
        backgroundColor: HubSightColors.cardDark,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: HubSightColors.borderDark, width: 1),
        ),
        leading: widget.isInitialSetup
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: HubSightColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          l10n.serverConfigTitle,
          style: const TextStyle(
            color: HubSightColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: HubSightColors.primary,
          indicatorWeight: 2,
          labelColor: HubSightColors.primary,
          unselectedLabelColor: HubSightColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: [
            Tab(
              icon: const Icon(Icons.qr_code_scanner, size: 20),
              text: l10n.scanQrTabTitle,
            ),
            Tab(
              icon: const Icon(Icons.folder_open, size: 20),
              text: l10n.tabHscfgFile,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQrScanTab(l10n),
          _buildHscfgEnrollTab(l10n),
        ],
      ),
    );
  }

  Widget _buildQrScanTab(AppLocalizations l10n) {
    return Column(
      children: [
        // Instructions Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Text(
            l10n.scanQrDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: HubSightColors.textMuted,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ),

        // Camera Preview Area
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: HubSightRadius.roundedCard,
              border: Border.all(color: HubSightColors.borderDark, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) => _onDetectBarcode(capture, l10n),
                  errorBuilder: (context, error) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.camera_alt_outlined,
                              color: HubSightColors.textMuted,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.cameraPermissionRequired,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: HubSightColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Viewfinder Frame Overlay
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: HubSightColors.primary, width: 2),
                      borderRadius: HubSightRadius.roundedCard,
                    ),
                  ),
                ),

                // Floating Camera Controls (Torch & Camera Flip)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.flash_on, size: 20),
                        onPressed: () => _scannerController.toggleTorch(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.cameraswitch_outlined, size: 20),
                        onPressed: () => _scannerController.switchCamera(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Error message if QR is invalid
        if (_qrError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: HubSightColors.errorBg,
                borderRadius: HubSightRadius.roundedXl,
                border: Border.all(color: HubSightColors.errorBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: HubSightColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _qrError!,
                      style: const TextStyle(color: HubSightColors.errorText, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Fallback Button: Pick QR image from gallery
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _handlePickQrImage(l10n),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: HubSightColors.borderDark),
                backgroundColor: HubSightColors.surfaceDark,
                foregroundColor: HubSightColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: HubSightRadius.roundedXl,
                ),
              ),
              icon: const Icon(Icons.image_outlined, size: 20, color: HubSightColors.textSecondary),
              label: Text(
                l10n.scanQrPickImage,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: HubSightColors.textPrimary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHscfgEnrollTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HubSightColors.cardDark,
              borderRadius: HubSightRadius.roundedCard,
              border: Border.all(color: HubSightColors.borderDark),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_reset, color: HubSightColors.primary, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.enrollHscfgTitle,
                        style: const TextStyle(
                          color: HubSightColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.enrollHscfgDesc,
                        style: const TextStyle(
                          color: HubSightColors.textMuted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // File Picker Button
          InkWell(
            onTap: _handlePickFile,
            borderRadius: HubSightRadius.roundedCard,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: HubSightColors.cardDark,
                borderRadius: HubSightRadius.roundedCard,
                border: Border.all(
                  color: _hscfgBytes != null ? const Color(0xFF10B981) : HubSightColors.borderDark,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _hscfgBytes != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                    color: _hscfgBytes != null ? const Color(0xFF10B981) : HubSightColors.primary,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _hscfgFileName != null
                        ? l10n.fileSelected(_hscfgFileName!)
                        : l10n.pickHscfgFile,
                    style: TextStyle(
                      color: _hscfgBytes != null ? const Color(0xFF10B981) : HubSightColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 6-digit PIN Input
          Text(
            l10n.pinLabel,
            style: const TextStyle(
              color: HubSightColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _filePinController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscureText: true,
            style: const TextStyle(
              color: HubSightColors.textPrimary,
              fontSize: 20,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              hintStyle: const TextStyle(color: HubSightColors.textMuted, letterSpacing: 8),
              filled: true,
              fillColor: HubSightColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: HubSightRadius.roundedXl,
                borderSide: const BorderSide(color: HubSightColors.borderDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: HubSightRadius.roundedXl,
                borderSide: const BorderSide(color: HubSightColors.borderDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: HubSightRadius.roundedXl,
                borderSide: const BorderSide(color: HubSightColors.primary, width: 1.5),
              ),
            ),
          ),

          if (_fileEnrollError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HubSightColors.errorBg,
                borderRadius: HubSightRadius.roundedXl,
                border: Border.all(color: HubSightColors.errorBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: HubSightColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fileEnrollError!,
                      style: const TextStyle(color: HubSightColors.errorText, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isEnrollingFile ? null : () => _handleEnrollHscfg(l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: HubSightColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: HubSightRadius.roundedXl),
                elevation: 0,
              ),
              child: _isEnrollingFile
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      l10n.enrollButton,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
