import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cctv_app/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';
import '../../core/localization/error_localizer.dart';
import '../../core/network/sdk_provider.dart';
import '../auth/login_screen.dart';

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

  // Zero-Config Enrollment (.hscfg)
  Uint8List? _hscfgBytes;
  String? _hscfgFileName;
  final _pinController = TextEditingController();
  bool _isEnrolling = false;
  String? _enrollError;

  // Manual Setup
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _isTesting = false;
  bool _isSaving = false;
  String? _manualMessage;
  bool _manualSuccess = false;
  String? _manualError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final sdk = ref.read(hubsightSdkProvider);
    if (sdk != null) {
      _urlController.text = sdk.config.urls.gatewayUrl;
      _apiKeyController.text = sdk.config.apiKey;
    } else {
      _urlController.text = 'http://10.0.2.2:8088';
      _apiKeyController.text = 'hs_mob_client_default';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pinController.dispose();
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

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
            _enrollError = null;
          });
        }
      }
    } catch (e) {
      setState(() => _enrollError = 'Không thể chọn tệp: $e');
    }
  }

  Future<void> _handleEnrollHscfg(AppLocalizations l10n) async {
    final pin = _pinController.text.trim();
    if (_hscfgBytes == null) {
      setState(() => _enrollError = l10n.pickHscfgFile);
      return;
    }
    if (pin.length != 6 || int.tryParse(pin) == null) {
      setState(() => _enrollError = l10n.errConfigInvalidPin);
      return;
    }

    setState(() {
      _isEnrolling = true;
      _enrollError = null;
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
          _enrollError = AppErrorLocalizer.localize(e, l10n);
        });
      }
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  HubSightAppConfig _buildManualConfig() {
    final rawUrl = _urlController.text.trim().replaceAll(RegExp(r'/+$'), '');
    final wsScheme = rawUrl.startsWith('https://') ? 'wss://' : 'ws://';
    final hostPort = rawUrl.replaceFirst(RegExp(r'^https?://'), '');
    final apiKey = _apiKeyController.text.trim();

    return HubSightAppConfig(
      urls: HubSightUrls(
        gatewayUrl: rawUrl,
        apiBaseUrl: '$rawUrl/api',
        relayWsUrl: '$wsScheme$hostPort/relay',
        webrtcBaseUrl: '$rawUrl:8555',
      ),
      key: HubSightClientKey(
        clientId: apiKey,
        clientSecret: apiKey,
        clientName: 'Mobile Client (Manual)',
      ),
      metadata: const HubSightConfigMetadata(
        formatVersion: '1.0',
        configId: 'cfg_manual',
        name: 'Manual Server Setup',
      ),
    );
  }

  Future<void> _handleTestConnection(AppLocalizations l10n) async {
    final url = _urlController.text.trim();
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      setState(() => _manualError = l10n.serverUrlInvalid);
      return;
    }

    setState(() {
      _isTesting = true;
      _manualMessage = null;
      _manualError = null;
    });

    try {
      final tempConfig = _buildManualConfig();
      final tempSdk = await HubSightSDK.initialize(config: tempConfig);
      final status = await tempSdk.client.get(Endpoints.systemStatus);
      tempSdk.dispose();

      if (mounted) {
        setState(() {
          _manualSuccess = status is Map && status['status'] == 'ok';
          _manualMessage = _manualSuccess ? l10n.connectionSuccess : l10n.connectionFailed;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _manualSuccess = false;
          _manualMessage = l10n.connectionFailed;
        });
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _handleSaveManual(AppLocalizations l10n) async {
    final url = _urlController.text.trim();
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      setState(() => _manualError = l10n.serverUrlInvalid);
      return;
    }

    setState(() {
      _isSaving = true;
      _manualError = null;
    });

    try {
      final config = _buildManualConfig();
      await ref.read(hubsightSdkProvider.notifier).initializeFromConfig(config);

      if (mounted) {
        _navigateAfterSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _manualError = AppErrorLocalizer.localize(e, l10n));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isInitialSetup
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          l10n.serverConfigTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE85D10),
          indicatorWeight: 3,
          labelColor: const Color(0xFFE85D10),
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: [
            Tab(text: l10n.enrollHscfgTitle),
            Tab(text: l10n.orManualSetup),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHscfgEnrollTab(l10n),
          _buildManualSetupTab(l10n),
        ],
      ),
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
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_reset, color: Color(0xFFE85D10), size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.enrollHscfgTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.enrollHscfgDesc,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
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
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hscfgBytes != null ? const Color(0xFF10B981) : const Color(0xFF475569),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _hscfgBytes != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                    color: _hscfgBytes != null ? const Color(0xFF10B981) : const Color(0xFFE85D10),
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _hscfgFileName != null
                        ? l10n.fileSelected(_hscfgFileName!)
                        : l10n.pickHscfgFile,
                    style: TextStyle(
                      color: _hscfgBytes != null ? const Color(0xFF10B981) : Colors.white,
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
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscureText: true,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              hintStyle: const TextStyle(color: Color(0xFF475569), letterSpacing: 8),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE85D10), width: 1.5),
              ),
            ),
          ),

          if (_enrollError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _enrollError!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12.5),
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
              onPressed: _isEnrolling ? null : () => _handleEnrollHscfg(l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE85D10),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isEnrolling
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

  Widget _buildManualSetupTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.serverUrlLabel,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'https://cctv.quoctran.space',
              hintStyle: const TextStyle(color: Color(0xFF475569)),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE85D10), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            l10n.apiKeyLabel,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'hs_mob_client_default',
              hintStyle: const TextStyle(color: Color(0xFF475569)),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE85D10), width: 1.5),
              ),
            ),
          ),

          if (_manualMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _manualSuccess
                    ? const Color(0xFF10B981).withOpacity(0.15)
                    : Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _manualSuccess
                      ? const Color(0xFF10B981).withOpacity(0.3)
                      : Colors.redAccent.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _manualSuccess ? Icons.check_circle : Icons.error_outline,
                    color: _manualSuccess ? const Color(0xFF10B981) : Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _manualMessage!,
                      style: TextStyle(
                        color: _manualSuccess ? const Color(0xFF10B981) : Colors.redAccent,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_manualError != null) ...[
            const SizedBox(height: 14),
            Text(_manualError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
          ],

          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isTesting ? null : () => _handleTestConnection(l10n),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF475569)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isTesting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          l10n.testConnection,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _handleSaveManual(l10n),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE85D10),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          l10n.continueButton,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
