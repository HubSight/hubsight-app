import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/socket_service.dart';
import '../../core/storage/storage_service.dart';
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

class _ServerConfigScreenState extends ConsumerState<ServerConfigScreen> {
  final _urlController = TextEditingController();
  bool _isTesting = false;
  bool _isSaving = false;
  String? _testMessage;
  bool _testSuccess = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final storage = ref.read(storageServiceProvider);
    final savedUrl = storage.getServerUrl();
    _urlController.text = savedUrl ?? 'http://10.0.2.2:8088';
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleTestConnection(AppLocalizations l10n) async {
    final url = _urlController.text.trim();
    if (!_validateUrl(url, l10n)) return;

    setState(() {
      _isTesting = true;
      _testMessage = null;
    });

    final apiClient = ref.read(apiClientProvider);
    final success = await apiClient.testConnection(url);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = success;
        _testMessage = success ? l10n.connectionSuccess : l10n.connectionFailed;
      });
    }
  }

  bool _validateUrl(String url, AppLocalizations l10n) {
    if (url.isEmpty) {
      setState(() => _validationError = l10n.serverUrlEmpty);
      return false;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() => _validationError = l10n.serverUrlInvalid);
      return false;
    }
    setState(() => _validationError = null);
    return true;
  }

  Future<void> _handleSaveAndContinue(AppLocalizations l10n) async {
    final url = _urlController.text.trim();
    if (!_validateUrl(url, l10n)) return;

    setState(() => _isSaving = true);

    final storage = ref.read(storageServiceProvider);
    await storage.setServerUrl(url);

    // Update runtime clients
    ref.read(apiClientProvider).updateServerUrl(url);
    ref.read(socketServiceProvider).updateServerUrl(url);

    if (mounted) {
      setState(() => _isSaving = false);
      if (widget.isInitialSetup) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(l10n.connectionSuccess),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate background for premium look
      appBar: widget.isInitialSetup
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),

              // Top Logo & Header
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE85D10),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE85D10).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.dns_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Center(
                child: Text(
                  'HubSight',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  l10n.serverConfigTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // White Content Container (Bottom Sheet Style)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.serverConfigSubtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Label
                    Text(
                      l10n.serverUrlLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Server URL Input Field
                    TextField(
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.serverUrlHint,
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                        prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF64748B), size: 20),
                        suffixIcon: _urlController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
                                onPressed: () {
                                  _urlController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: _validationError != null
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE85D10), width: 1.8),
                        ),
                      ),
                      onChanged: (val) {
                        if (_validationError != null) {
                          setState(() => _validationError = null);
                        }
                      },
                    ),

                    if (_validationError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _validationError!,
                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                      ),
                    ],

                    const SizedBox(height: 6),
                    Text(
                      l10n.serverUrlHelp,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Test Connection Button
                    OutlinedButton.icon(
                      onPressed: _isTesting ? null : () => _handleTestConnection(l10n),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFE85D10),
                              ),
                            )
                          : const Icon(Icons.wifi_find_rounded, size: 18, color: Color(0xFF475569)),
                      label: Text(
                        l10n.testConnection,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),

                    if (_testMessage != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _testSuccess ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _testSuccess ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _testSuccess ? Icons.check_circle : Icons.error_outline,
                              size: 16,
                              color: _testSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _testMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _testSuccess ? const Color(0xFF065F46) : const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Continue Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : () => _handleSaveAndContinue(l10n),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE85D10),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.continueButton,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Footer
              Center(
                child: Text(
                  l10n.footerVersion,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Center(
                child: Text(
                  l10n.footerCopyright,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

