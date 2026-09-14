import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubsight_app/l10n/app_localizations.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/localization/error_localizer.dart';
import '../../core/network/sdk_provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

/// The 5 steps of the Server Config Wizard.
enum ConfigWizardStep {
  welcome,      // Step 1: Welcome / Introduction
  selectMethod, // Step 2: Choose File or QR
  pickFile,     // Step 3a: File Picker (.hscfg)
  scanQr,       // Step 3b: QR Scanner & Temp Download
  enterPin,     // Step 4: 6-digit Passcode Entry & Decryption
  summary,      // Step 5: Summary & Final Confirmation
}

/// Method chosen in Step 2.
enum ConfigMethod {
  file,
  qr,
}

class ServerConfigScreen extends ConsumerStatefulWidget {
  final bool isInitialSetup;
  final ConfigWizardStep initialStep;

  final Uint8List? initialConfigBytes;
  final String? initialConfigFileName;

  const ServerConfigScreen({
    super.key,
    this.isInitialSetup = true,
    this.initialStep = ConfigWizardStep.welcome,
    this.initialConfigBytes,
    this.initialConfigFileName,
  });

  @override
  ConsumerState<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends ConsumerState<ServerConfigScreen> {
  // Wizard Navigation State
  late ConfigWizardStep _currentStep;
  ConfigMethod _selectedMethod = ConfigMethod.qr;

  // File & QR Data
  Uint8List? _configBytes;
  String? _configFileName;
  int? _configFileSize;
  HubSightQRPayload? _qrPayload;

  // Passcode & Decryption State
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  HubSightAppConfig? _decryptedConfig;

  // Async / Loading / Error States
  bool _isLoading = false;
  String _loadingMessage = '';
  String? _errorMessage;

  // QR Scanner Controller
  late MobileScannerController _scannerController;
  bool _isQrProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _configBytes = widget.initialConfigBytes;
    _configFileName = widget.initialConfigFileName;
    _configFileSize = widget.initialConfigBytes?.length;
    _pinController.addListener(_updatePinState);
    _scannerController = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.normal,
    );
    if (widget.initialStep == ConfigWizardStep.summary && _decryptedConfig == null) {
      _decryptedConfig = const HubSightAppConfig(
        urls: HubSightUrls(
          gatewayUrl: 'https://cctv.quoctran.space',
          apiBaseUrl: 'https://cctv.quoctran.space/api',
          relayWsUrl: 'wss://cctv.quoctran.space/relay',
          webrtcBaseUrl: 'https://cctv.quoctran.space:8555',
        ),
        key: HubSightClientKey(
          clientId: 'hs_client_892b1a',
          clientSecret: 'hs_sec_9941a',
          clientName: 'HubSight Mobile Client',
        ),
        metadata: HubSightConfigMetadata(
          formatVersion: '1.0',
          configId: 'cfg_89f02e1a',
          name: 'HubSight HQ Security Enclave',
          createdBy: 'SecOps Administrator',
          createdAtUtc: '2026-09-13T10:00:00Z',
        ),
      );
    }
    if (widget.initialStep == ConfigWizardStep.enterPin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pinFocusNode.requestFocus();
        }
      });
    }
  }

  void _updatePinState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pinController.removeListener(_updatePinState);
    _pinController.dispose();
    _pinFocusNode.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // Step Navigation Helpers
  // ===========================================================================

  void _goToStep(ConfigWizardStep step) {
    setState(() {
      _errorMessage = null;
      _currentStep = step;
    });
    if (step == ConfigWizardStep.enterPin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pinFocusNode.requestFocus();
        }
      });
    }
  }

  void _handleBack() {
    setState(() => _errorMessage = null);
    switch (_currentStep) {
      case ConfigWizardStep.welcome:
        if (!widget.isInitialSetup && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        break;
      case ConfigWizardStep.selectMethod:
        _goToStep(ConfigWizardStep.welcome);
        break;
      case ConfigWizardStep.pickFile:
      case ConfigWizardStep.scanQr:
        _goToStep(ConfigWizardStep.selectMethod);
        break;
      case ConfigWizardStep.enterPin:
        if (_selectedMethod == ConfigMethod.file) {
          _goToStep(ConfigWizardStep.pickFile);
        } else {
          _goToStep(ConfigWizardStep.scanQr);
        }
        break;
      case ConfigWizardStep.summary:
        _goToStep(ConfigWizardStep.enterPin);
        break;
    }
  }

  // ===========================================================================
  // Step 3a: Pick File Handler
  // ===========================================================================

  Future<void> _handlePickFile([AppLocalizations? l10n]) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          try {
            bytes = await File(file.path!).readAsBytes();
          } catch (_) {}
        }
        if (bytes != null) {
          final loadedBytes = bytes;
          setState(() {
            _configBytes = loadedBytes;
            _configFileName = file.name;
            _configFileSize = loadedBytes.length;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        final loc = l10n ?? AppLocalizations.of(context);
        setState(() => _errorMessage = loc != null ? loc.configPickFileError(e.toString()) : 'Cannot select file: $e');
      }
    }
  }

  // ===========================================================================
  // Step 3b: QR Scanner & OS Temp Download Handlers
  // ===========================================================================

  void _onDetectBarcode(BarcodeCapture capture, AppLocalizations l10n) {
    if (_isQrProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;
    final raw = barcode.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    _processScannedQrData(raw.trim(), l10n);
  }

  Future<void> _handlePickQrImage(AppLocalizations l10n) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        final capture = await _scannerController.analyzeImage(result.files.first.path!);
        final raw = capture?.barcodes.firstOrNull?.rawValue;
        if (raw != null && raw.trim().isNotEmpty) {
          _processScannedQrData(raw.trim(), l10n);
        } else {
          setState(() => _errorMessage = l10n.scanQrInvalidPayload);
        }
      }
    } catch (e) {
      setState(() => _errorMessage = l10n.configQrAnalyzeError(e.toString()));
    }
  }

  Future<void> _processScannedQrData(String rawData, AppLocalizations l10n) async {
    HubSightQRPayload payload;
    try {
      payload = HubSightQRPayload.fromString(rawData);
    } catch (_) {
      setState(() => _errorMessage = l10n.scanQrInvalidPayload);
      return;
    }

    setState(() {
      _isQrProcessing = true;
      _isLoading = true;
      _loadingMessage = l10n.scanQrDownloading;
      _errorMessage = null;
      _qrPayload = payload;
    });

    try {
      // 1. Download container bytes from server
      final dio = Dio();
      final response = await dio.get<List<int>>(
        payload.downloadUrl,
        options: Options(
          responseType: ResponseType.bytes,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.data == null || response.data!.isEmpty) {
        throw Exception(l10n.configNoDataFromServer);
      }

      final downloadedBytes = Uint8List.fromList(response.data!);

      // 2. Validate SHA-256 Checksum if present in QR payload
      if (payload.sha256.isNotEmpty) {
        final digest = sha256.convert(downloadedBytes).toString();
        if (digest.toLowerCase() != payload.sha256.toLowerCase()) {
          throw HubSightConfigException(
            code: HubSightErrorCode.configCorrupted,
            developerMessage: l10n.scanQrChecksumMismatch,
          );
        }
      }

      // 3. Save config file to OS temporary folder
      final tempDir = Directory.systemTemp;
      final safeId = payload.configId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final tempFilePath = '${tempDir.path}/.hubsight_config_$safeId.hscfg';
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(downloadedBytes);

      if (mounted) {
        setState(() {
          _configBytes = downloadedBytes;
          _configFileName = 'qr_$safeId.hscfg';
          _configFileSize = downloadedBytes.length;
          _isLoading = false;
          _loadingMessage = '';
          _isQrProcessing = false;
        });

        // Automatically advance to Step 4 (Passcode Entry)
        _goToStep(ConfigWizardStep.enterPin);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = '';
          _isQrProcessing = false;
          _errorMessage = AppErrorLocalizer.localize(e, l10n);
        });
      }
    }
  }

  // ===========================================================================
  // Step 4: Decrypt & Unpack Container Handler
  // ===========================================================================

  Future<void> _handleDecrypt(AppLocalizations l10n) async {
    final pin = _pinController.text.trim();
    if (_configBytes == null) {
      setState(() => _errorMessage = l10n.configNoFileSelectedError);
      return;
    }
    if (pin.length != 6 || int.tryParse(pin) == null) {
      setState(() => _errorMessage = l10n.errConfigInvalidPin);
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = l10n.configDecryptingSignature;
      _errorMessage = null;
    });

    try {
      // Decrypt container with Argon2id + AES-GCM + Ed25519 signature validation
      final appConfig = await HscfgDecoder.decrypt(
        fileBytes: _configBytes!,
        pin6Digits: pin,
        verifySignature: true,
      );

      if (mounted) {
        setState(() {
          _decryptedConfig = appConfig;
          _isLoading = false;
          _loadingMessage = '';
        });

        // Advance to Step 5 (Summary & Confirmation)
        _goToStep(ConfigWizardStep.summary);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = '';
          _errorMessage = AppErrorLocalizer.localize(e, l10n);
        });
      }
    }
  }

  // ===========================================================================
  // Step 5: Save Config & Navigate to Login Handler
  // ===========================================================================

  Future<void> _handleConfirmAndSave(AppLocalizations l10n) async {
    if (_decryptedConfig == null) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = l10n.configSavingSystem;
    });

    try {
      // Initialize SDK and persist config securely
      await ref.read(hubsightSdkProvider.notifier).initializeFromConfig(_decryptedConfig!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.configSuccessLoginPrompt),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = '';
          _errorMessage = l10n.configSaveError(e.toString());
        });
      }
    }
  }

  // ===========================================================================
  // Build Main Wizard Structure (High-Tech Cyberpunk Security Terminal)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFF07090E),
        appBar: _buildWizardAppBar(l10n),
        body: Stack(
          children: [
            // Ambient Cyber Radial Glow at the top
            Positioned(
              top: -120,
              left: -60,
              right: -60,
              height: 380,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.1,
                    colors: [
                      HubSightColors.primary.withValues(alpha: 0.18),
                      const Color(0x28431407),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Main Content Area
            SafeArea(
              child: Column(
                children: [
                  // Step Progress Indicator (visible on steps 2, 3, 4, 5)
                  if (_currentStep != ConfigWizardStep.welcome) _buildStepProgress(),

                  // Active Step Content
                  Expanded(
                    child: _isLoading && _currentStep != ConfigWizardStep.scanQr
                        ? _buildLoadingState(l10n)
                        : _buildActiveStepView(l10n),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildWizardAppBar(AppLocalizations l10n) {
    final showBack = _currentStep != ConfigWizardStep.welcome || !widget.isInitialSetup;

    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: Border(
        bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: InkWell(
                  onTap: _handleBack,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            )
          : null,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getStepTitle(l10n),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'HUBSIGHT SECURITY ENCLAVE',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: HubSightColors.primaryLight.withValues(alpha: 0.85),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  String _getStepTitle(AppLocalizations l10n) {
    switch (_currentStep) {
      case ConfigWizardStep.welcome:
        return l10n.configStepWelcome;
      case ConfigWizardStep.selectMethod:
        return l10n.configStepMethod;
      case ConfigWizardStep.pickFile:
        return l10n.configStepPickFile;
      case ConfigWizardStep.scanQr:
        return l10n.configStepScanQr;
      case ConfigWizardStep.enterPin:
        return l10n.configStepPin;
      case ConfigWizardStep.summary:
        return l10n.configStepSummary;
    }
  }

  Widget _buildStepProgress() {
    int activeIndex = 0;
    String stepLabel = '01 // METHOD SELECTION';
    switch (_currentStep) {
      case ConfigWizardStep.welcome:
        activeIndex = 0;
        stepLabel = '00 // INITIALIZATION';
        break;
      case ConfigWizardStep.selectMethod:
        activeIndex = 1;
        stepLabel = '01 // METHOD SELECTION';
        break;
      case ConfigWizardStep.pickFile:
      case ConfigWizardStep.scanQr:
        activeIndex = 2;
        stepLabel = _currentStep == ConfigWizardStep.pickFile
            ? '02 // LOCAL CONTAINER IMPORT'
            : '02 // RADAR QR SCANNER';
        break;
      case ConfigWizardStep.enterPin:
        activeIndex = 3;
        stepLabel = '03 // PASSCODE & DECRYPT';
        break;
      case ConfigWizardStep.summary:
        activeIndex = 4;
        stepLabel = '04 // VERIFY & LAUNCH';
        break;
    }

    const totalSteps = 4; // 1: Method, 2: Input, 3: PIN, 4: Summary

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0F17).withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'SECURITY PROTOCOL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: Colors.white.withValues(alpha: 0.4),
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stepLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: HubSightColors.primaryLight,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 1; i <= totalSteps; i++) ...[
                Expanded(
                  child: Container(
                    height: 3.5,
                    decoration: BoxDecoration(
                      gradient: i <= activeIndex
                          ? const LinearGradient(
                              colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                            )
                          : null,
                      color: i <= activeIndex ? null : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: i <= activeIndex
                          ? [
                              BoxShadow(
                                color: HubSightColors.primary.withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 0.5,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
                if (i < totalSteps) const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveStepView(AppLocalizations l10n) {
    switch (_currentStep) {
      case ConfigWizardStep.welcome:
        return _buildStep1Welcome(l10n);
      case ConfigWizardStep.selectMethod:
        return _buildStep2SelectMethod(l10n);
      case ConfigWizardStep.pickFile:
        return _buildStep3aPickFile(l10n);
      case ConfigWizardStep.scanQr:
        return _buildStep3bScanQr(l10n);
      case ConfigWizardStep.enterPin:
        return _buildStep4EnterPin(l10n);
      case ConfigWizardStep.summary:
        return _buildStep5Summary(l10n);
    }
  }

  Widget _buildLoadingState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF10141F),
                shape: BoxShape.circle,
                border: Border.all(color: HubSightColors.primary.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: HubSightColors.primary.withValues(alpha: 0.25),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(
                  color: HubSightColors.primary,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _loadingMessage.isNotEmpty ? _loadingMessage : l10n.processing,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'HUBSIGHT SECURE ENCLAVE ACTIVE',
              style: TextStyle(
                color: HubSightColors.primaryLight.withValues(alpha: 0.7),
                fontSize: 10,
                letterSpacing: 1.5,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Step 1: Welcome View (Cyberpunk Security Core)
  // ===========================================================================

  Widget _buildStep1Welcome(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // Glowing Concentric Cyber Security Core
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing laser ring
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: HubSightColors.primary.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: HubSightColors.primary.withValues(alpha: 0.15),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              // Middle cyber ring
              Container(
                width: 102,
                height: 102,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: HubSightColors.primary.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
              ),
              // Core Glowing Emblem
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: HubSightColors.primary.withValues(alpha: 0.55),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Cyber Tech Badges Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTechBadge('AES-256-GCM'),
              const SizedBox(width: 8),
              _buildTechBadge('ARGON2ID'),
              const SizedBox(width: 8),
              _buildTechBadge('ED25519-SIG'),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            l10n.configWelcomeTitle,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          Text(
            l10n.configWelcomeSubtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.65),
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Security Highlights Modules
          _buildFeatureItem(
            icon: Icons.lock_outline_rounded,
            title: l10n.configFeatureE2eeTitle,
            subtitle: l10n.configFeatureE2eeDesc,
          ),
          const SizedBox(height: 14),
          _buildFeatureItem(
            icon: Icons.verified_user_outlined,
            title: l10n.configFeatureEd25519Title,
            subtitle: l10n.configFeatureEd25519Desc,
          ),
          const SizedBox(height: 14),
          _buildFeatureItem(
            icon: Icons.bolt_rounded,
            title: l10n.configFeatureZeroConfigTitle,
            subtitle: l10n.configFeatureZeroConfigDesc,
          ),

          const SizedBox(height: 36),

          // Primary Glowing Laser CTA Button
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEA580C)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: HubSightColors.primary.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _goToStep(ConfigWizardStep.selectMethod),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.configStartSetup,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: HubSightColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: HubSightColors.primary.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Color(0xFFFB923C),
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10141F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: HubSightColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HubSightColors.primary.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: HubSightColors.primaryLight, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Step 2: Select Method (File or QR - Tactical Cyber Cards)
  // ===========================================================================

  Widget _buildStep2SelectMethod(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.configSelectMethodTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.configSelectMethodDesc,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.65),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // Option 1: QR Scanner
          _buildMethodCard(
            icon: Icons.qr_code_scanner_rounded,
            title: l10n.configMethodQrTitle,
            subtitle: l10n.configMethodQrDesc,
            badge: l10n.configMethodRecommended,
            onTap: () {
              setState(() => _selectedMethod = ConfigMethod.qr);
              _goToStep(ConfigWizardStep.scanQr);
            },
          ),
          const SizedBox(height: 16),

          // Option 2: Import File
          _buildMethodCard(
            icon: Icons.file_present_rounded,
            title: l10n.configMethodFileTitle,
            subtitle: l10n.configMethodFileDesc,
            badge: null,
            onTap: () {
              setState(() => _selectedMethod = ConfigMethod.file);
              _goToStep(ConfigWizardStep.pickFile);
            },
          ),

          const Spacer(),

          // Back Button in Cyber Glass
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _handleBack,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                backgroundColor: Colors.white.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                l10n.backButton,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF10141F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HubSightColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: HubSightColors.primary.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: HubSightColors.primaryLight, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF34D399),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: HubSightColors.primaryLight, size: 22),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Step 3a: Pick File View (.hscfg - Cyber Radar Dropzone)
  // ===========================================================================

  Widget _buildStep3aPickFile(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.configPickFileTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.configPickFileSubtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.65),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // File Picker Dropzone Card (Cyber Radar Style)
          InkWell(
            onTap: () => _handlePickFile(l10n),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF10141F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _configBytes != null
                      ? const Color(0xFF10B981)
                      : Colors.white.withValues(alpha: 0.12),
                  width: _configBytes != null ? 1.8 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _configBytes != null
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glowing concentric radar emblem
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _configBytes != null
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : HubSightColors.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _configBytes != null
                            ? const Color(0xFF10B981).withValues(alpha: 0.4)
                            : HubSightColors.primary.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _configBytes != null
                              ? const Color(0xFF10B981).withValues(alpha: 0.25)
                              : HubSightColors.primary.withValues(alpha: 0.25),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Icon(
                      _configBytes != null ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                      color: _configBytes != null ? const Color(0xFF34D399) : HubSightColors.primaryLight,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _configFileName ?? l10n.configTapToPickFile,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _configBytes != null
                        ? l10n.configFileSizeKb(((_configFileSize ?? 0) / 1024).toStringAsFixed(1))
                        : l10n.configStandardFormatSupport,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  if (_configBytes != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_rounded, color: Color(0xFF34D399), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            l10n.configReadyToDecrypt,
                            style: const TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _handlePickFile(l10n),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(
                        l10n.configPickAnotherFile,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorAlert(_errorMessage!),
          ],

          const SizedBox(height: 40),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _handleBack,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      l10n.backButton,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: _configBytes != null
                        ? const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)])
                        : null,
                    color: _configBytes == null ? Colors.white.withValues(alpha: 0.08) : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _configBytes != null
                        ? [
                            BoxShadow(
                              color: HubSightColors.primary.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: _configBytes != null ? () => _goToStep(ConfigWizardStep.enterPin) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.continueButton, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Step 3b: QR Scanner View (Tactical Cyber HUD)
  // ===========================================================================

  Widget _buildStep3bScanQr(AppLocalizations l10n) {
    return Column(
      children: [
        // Camera Viewport with Tactical HUD
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: (capture) => _onDetectBarcode(capture, l10n),
              ),

              // Tactical Viewfinder HUD with glowing corner brackets & crosshairs
              Center(
                child: CustomPaint(
                  size: const Size(260, 260),
                  painter: TacticalViewfinderPainter(),
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: HubSightColors.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),

              // Top HUD Telemetry Banner
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF07090E).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF10B981),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.configQrInstruction,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading Overlay during download
              if (_isLoading)
                Container(
                  color: const Color(0xFF07090E).withValues(alpha: 0.85),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: HubSightColors.primary, strokeWidth: 3),
                        const SizedBox(height: 16),
                        Text(
                          _loadingMessage,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Controls bar below camera (Tactical Dark Glass)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0C0F17),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null) ...[
                _buildErrorAlert(_errorMessage!),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.flash_on_rounded),
                    tooltip: l10n.configFlashTooltip,
                    color: Colors.white.withValues(alpha: 0.8),
                    onPressed: () => _scannerController.toggleTorch(),
                  ),
                  Flexible(
                    child: OutlinedButton.icon(
                      onPressed: () => _handlePickQrImage(l10n),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(
                        l10n.configQrPickGallery,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios_rounded),
                    tooltip: l10n.configSwitchCameraTooltip,
                    color: Colors.white.withValues(alpha: 0.8),
                    onPressed: () => _scannerController.switchCamera(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Step 4: Enter PIN (Passcode 6-digits - Cyber Digital Cells)
  // ===========================================================================

  Widget _buildStep4EnterPin(AppLocalizations l10n) {
    final sourceLabel = _selectedMethod == ConfigMethod.file
        ? 'FILE // ${_configFileName ?? "hubsight.hscfg"}'
        : 'QR PAYLOAD // ${_qrPayload?.name.isNotEmpty == true ? _qrPayload!.name : (_qrPayload?.configId ?? l10n.configQrFallbackName)}';

    final pinText = _pinController.text;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.configEnterPinTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.configEnterPinSubtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.65),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Tactical Source Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10141F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _selectedMethod == ConfigMethod.file ? Icons.insert_drive_file_outlined : Icons.qr_code_2_rounded,
                  size: 16,
                  color: HubSightColors.primaryLight,
                ),
                const SizedBox(width: 8),
                Text(
                  sourceLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // 6 Discrete Glowing Digital PIN Cells Stacked with Hidden Functional TextField
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _pinFocusNode.requestFocus(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildPinCells(pinText),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.0,
                    child: TextField(
                      key: const Key('config-pin-input-field'),
                      controller: _pinController,
                      focusNode: _pinFocusNode,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofocus: true,
                      showCursor: false,
                      enableInteractiveSelection: false,
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleDecrypt(l10n),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 24),
            _buildErrorAlert(_errorMessage!),
          ],

          const SizedBox(height: 48),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _handleBack,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      l10n.backButton,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: HubSightColors.primary.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _handleDecrypt(l10n),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_open_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            l10n.configDecryptButton,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinCells(String currentPin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < currentPin.length;
        final isCurrent = index == currentPin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 44,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFF10141F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFilled
                  ? HubSightColors.primary
                  : isCurrent
                      ? HubSightColors.primary.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.12),
              width: isFilled || isCurrent ? 1.8 : 1.0,
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: HubSightColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: isFilled
              ? Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF97316),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFF97316),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                )
              : isCurrent
                  ? Container(
                      width: 14,
                      height: 2,
                      color: HubSightColors.primaryLight,
                    )
                  : Text(
                      '•',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
        );
      }),
    );
  }

  // ===========================================================================
  // Step 5: Summary & Confirmation View (Security Matrix)
  // ===========================================================================

  Widget _buildStep5Summary(AppLocalizations l10n) {
    final cfg = _decryptedConfig;
    if (cfg == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Holographic Verified Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CRYPTOGRAPHIC INTEGRITY: VERIFIED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF34D399),
                          fontFamily: 'monospace',
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.configDecryptionSuccess,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.configSignatureValid,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF34D399)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            l10n.configConfirmTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.configConfirmSubtitle,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.white.withValues(alpha: 0.65),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Detailed Security Configuration Table (Cyber Terminal Style)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF10141F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  _buildSummaryRow(l10n.configSummarySystemName, cfg.metadata.name.isNotEmpty ? cfg.metadata.name : 'HubSight CCTV'),
                  _buildSummaryRow(l10n.configSummaryConfigId, cfg.metadata.configId),
                  _buildSummaryRow(l10n.configSummaryGateway, cfg.urls.gatewayUrl),
                  _buildSummaryRow('API Base URL', cfg.urls.apiBaseUrl),
                  _buildSummaryRow('Relay WebSocket', cfg.urls.relayWsUrl),
                  _buildSummaryRow(l10n.configSummaryClientName, cfg.key.clientName),
                  _buildSummaryRow(l10n.configSummaryCreatedBy, cfg.metadata.createdBy),
                  _buildSummaryRow(l10n.configSummaryCreatedAt, cfg.metadata.createdAtUtc ?? l10n.none),
                  _buildSummaryRow(l10n.configSummaryProfileVersion, cfg.metadata.formatVersion, isLast: true),
                ],
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorAlert(_errorMessage!),
          ],

          const SizedBox(height: 32),

          // Primary Glowing CTA Confirmation Button
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: HubSightColors.primary.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _handleConfirmAndSave(l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.configConfirmAndProceed,
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Secondary Reset Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => _goToStep(ConfigWizardStep.welcome),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.6),
              ),
              child: Text(l10n.configResetFromScratch),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorAlert(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tactical HUD Corner Brackets and Crosshair Painter for QR Scanner Viewfinder.
class TacticalViewfinderPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double strokeWidth;

  TacticalViewfinderPainter({
    this.color = const Color(0xFFF97316),
    this.cornerLength = 24.0,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = strokeWidth + 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    void drawCorner(double x1, double y1, double x2, double y2, double x3, double y3) {
      final path = Path()
        ..moveTo(x1, y1)
        ..lineTo(x2, y2)
        ..lineTo(x3, y3);
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }

    final w = size.width;
    final h = size.height;
    final l = cornerLength;

    // Top-left
    drawCorner(0, l, 0, 0, l, 0);
    // Top-right
    drawCorner(w - l, 0, w, 0, w, l);
    // Bottom-left
    drawCorner(0, h - l, 0, h, l, h);
    // Bottom-right
    drawCorner(w - l, h, w, h, w, h - l);

    // Center Crosshair
    final centerPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(w / 2 - 8, h / 2), Offset(w / 2 + 8, h / 2), centerPaint);
    canvas.drawLine(Offset(w / 2, h / 2 - 8), Offset(w / 2, h / 2 + 8), centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
