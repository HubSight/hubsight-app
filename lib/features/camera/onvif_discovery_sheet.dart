import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubsight_app/l10n/app_localizations.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';
import '../../core/network/sdk_provider.dart';
import '../../core/theme/app_theme.dart';

/// Modal bottom sheet and tool for ONVIF Device Discovery and Profile Inspection.
class OnvifDiscoverySheet extends ConsumerStatefulWidget {
  final List<Camera> existingCameras;
  final Camera? initialCamera;

  const OnvifDiscoverySheet({
    super.key,
    this.existingCameras = const [],
    this.initialCamera,
  });

  static Future<void> show(
    BuildContext context, {
    List<Camera> existingCameras = const [],
    Camera? initialCamera,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OnvifDiscoverySheet(
        existingCameras: existingCameras,
        initialCamera: initialCamera,
      ),
    );
  }

  @override
  ConsumerState<OnvifDiscoverySheet> createState() => _OnvifDiscoverySheetState();
}

class _OnvifDiscoverySheetState extends ConsumerState<OnvifDiscoverySheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  Camera? _selectedCamera;
  bool _isCustomMode = false;
  bool _isProbing = false;
  ONVIFProbeResult? _probeResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCamera = widget.initialCamera ?? (widget.existingCameras.isNotEmpty ? widget.existingCameras.first : null);
    _isCustomMode = _selectedCamera == null;

    _hostController = TextEditingController(text: _selectedCamera?.host ?? '');
    _portController = TextEditingController(text: '80');
    _usernameController = TextEditingController(text: 'admin');
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _runProbe() async {
    final sdk = ref.read(hubsightSdkProvider);
    if (sdk == null) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isProbing = true;
      _errorMessage = null;
      _probeResult = null;
    });

    try {
      final port = int.tryParse(_portController.text.trim()) ?? 80;
      final result = await sdk.cameras.probeONVIF(
        cameraId: !_isCustomMode ? _selectedCamera?.id : null,
        host: _isCustomMode ? _hostController.text.trim() : null,
        port: port,
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isProbing = false;
          _probeResult = result;
          if (!result.success && result.errorMessage != null) {
            _errorMessage = result.errorMessage;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProbing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: context.cardAdaptive,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag pill
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: context.borderAdaptive,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: HubSightRadius.roundedXl,
                      ),
                      child: const Icon(
                        Icons.radar_rounded,
                        color: Color(0xFF10B981),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.onvifDiscovery,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryAdaptive,
                            ),
                          ),
                          Text(
                            l10n.onvifDiscoverySubtitle,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: context.textSecondaryAdaptive,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: context.textMutedAdaptive),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(height: 1, color: context.borderAdaptive),
                const SizedBox(height: 16),

                // Selection Mode: Existing Camera vs Custom IP/Host
                if (widget.existingCameras.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Camera trong hệ thống', style: TextStyle(fontSize: 12)),
                          selected: !_isCustomMode,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _isCustomMode = false;
                                if (_selectedCamera != null) {
                                  _hostController.text = _selectedCamera!.host;
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Nhập IP tùy chỉnh', style: TextStyle(fontSize: 12)),
                          selected: _isCustomMode,
                          onSelected: (val) {
                            if (val) {
                              setState(() => _isCustomMode = true);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // Existing Camera Dropdown
                if (!_isCustomMode && widget.existingCameras.isNotEmpty) ...[
                  DropdownButtonFormField<Camera>(
                    initialValue: _selectedCamera,
                    decoration: InputDecoration(
                      labelText: 'Chọn camera',
                      filled: true,
                      fillColor: context.surfaceAdaptive,
                      border: OutlineInputBorder(
                        borderRadius: HubSightRadius.roundedLg,
                        borderSide: BorderSide(color: context.borderAdaptive),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: widget.existingCameras.map((c) {
                      return DropdownMenuItem<Camera>(
                        value: c,
                        child: Text('${c.name} (${c.host})'),
                      );
                    }).toList(),
                    onChanged: (c) {
                      if (c != null) {
                        setState(() {
                          _selectedCamera = c;
                          _hostController.text = c.host;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Custom Host Field
                if (_isCustomMode) ...[
                  TextFormField(
                    controller: _hostController,
                    decoration: InputDecoration(
                      labelText: l10n.probeHost,
                      hintText: '192.168.1.100 hoặc hostname',
                      filled: true,
                      fillColor: context.surfaceAdaptive,
                      border: OutlineInputBorder(
                        borderRadius: HubSightRadius.roundedLg,
                        borderSide: BorderSide(color: context.borderAdaptive),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Port & Credentials Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _portController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.probePort,
                          hintText: '80',
                          filled: true,
                          fillColor: context.surfaceAdaptive,
                          border: OutlineInputBorder(
                            borderRadius: HubSightRadius.roundedLg,
                            borderSide: BorderSide(color: context.borderAdaptive),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: l10n.probeUsername,
                          hintText: 'admin',
                          filled: true,
                          fillColor: context.surfaceAdaptive,
                          border: OutlineInputBorder(
                            borderRadius: HubSightRadius.roundedLg,
                            borderSide: BorderSide(color: context.borderAdaptive),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.probePassword,
                    hintText: 'Mật khẩu ONVIF (nếu có)',
                    filled: true,
                    fillColor: context.surfaceAdaptive,
                    border: OutlineInputBorder(
                      borderRadius: HubSightRadius.roundedLg,
                      borderSide: BorderSide(color: context.borderAdaptive),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Scan / Probe Button
                ElevatedButton.icon(
                  key: const Key('start-onvif-probe-button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: HubSightRadius.roundedLg),
                  ),
                  onPressed: _isProbing ? null : _runProbe,
                  icon: _isProbing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.search_rounded, size: 20),
                  label: Text(
                    _isProbing ? 'Đang dò tìm...' : l10n.probeCamera,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),

                // Error alert
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: HubSightColors.errorBg,
                      borderRadius: HubSightRadius.roundedLg,
                      border: Border.all(color: HubSightColors.errorBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: HubSightColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 12, color: HubSightColors.errorText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Probe Result Details
                if (_probeResult != null) ...[
                  const SizedBox(height: 18),
                  _buildResultCard(context, _probeResult!, l10n),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, ONVIFProbeResult res, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceAdaptive,
        borderRadius: HubSightRadius.roundedXl,
        border: Border.all(
          color: res.success ? const Color(0xFF10B981).withValues(alpha: 0.4) : HubSightColors.errorBorder,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result Status Banner
          Row(
            children: [
              Icon(
                res.success ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: res.success ? const Color(0xFF10B981) : HubSightColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  res.success ? l10n.probeSuccess : l10n.probeFailed,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: res.success ? const Color(0xFF10B981) : HubSightColors.errorText,
                  ),
                ),
              ),
              if (res.hasPtz)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.control_camera_rounded, size: 12, color: Color(0xFF3B82F6)),
                      SizedBox(width: 4),
                      Text(
                        'Hỗ trợ PTZ',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: context.borderAdaptive),
          const SizedBox(height: 12),

          // Hardware Info
          Text(
            'Thông tin thiết bị',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimaryAdaptive),
          ),
          const SizedBox(height: 6),
          _buildInfoRow('Nhà sản xuất', res.deviceInfo.manufacturer.isNotEmpty ? res.deviceInfo.manufacturer : 'ONVIF Standard'),
          _buildInfoRow('Mẫu mã (Model)', res.deviceInfo.model.isNotEmpty ? res.deviceInfo.model : 'IP Camera'),
          _buildInfoRow('Phiên bản Firmware', res.deviceInfo.firmwareVersion.isNotEmpty ? res.deviceInfo.firmwareVersion : 'N/A'),
          if (res.deviceInfo.serialNumber.isNotEmpty)
            _buildInfoRow('Số Serial', res.deviceInfo.serialNumber),

          const SizedBox(height: 12),
          Divider(height: 1, color: context.borderAdaptive),
          const SizedBox(height: 12),

          // Stream Profiles
          Text(
            'Cấu hình luồng (Media Profiles)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimaryAdaptive),
          ),
          const SizedBox(height: 6),
          if (res.profiles.isEmpty) ...[
            Text('Chưa trích xuất được profile media.', style: TextStyle(fontSize: 11.5, color: context.textMutedAdaptive)),
          ] else ...[
            ...res.profiles.map((p) {
              return Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.cardAdaptive,
                  borderRadius: HubSightRadius.roundedLg,
                  border: Border.all(color: context.borderAdaptive),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p.name.isNotEmpty ? p.name : p.token,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimaryAdaptive),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${p.width}x${p.height} @ ${p.fps}fps (${p.videoCodec})',
                            style: TextStyle(fontSize: 10, color: context.textSecondaryAdaptive),
                          ),
                        ),
                      ],
                    ),
                    if (p.streamUri != null && p.streamUri!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.streamUri!,
                              style: TextStyle(fontSize: 10.5, fontFamily: 'monospace', color: context.textMutedAdaptive),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 14),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: p.streamUri!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã sao chép RTSP Stream URI!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11.5, color: context.textSecondaryAdaptive)),
          Text(value, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.textPrimaryAdaptive)),
        ],
      ),
    );
  }
}
