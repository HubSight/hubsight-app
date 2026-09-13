import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubsight_app/l10n/app_localizations.dart';
import 'package:hubsight_sdk/hubsight_sdk.dart';
import '../../core/network/sdk_provider.dart';
import '../../core/theme/app_theme.dart';

/// Modal bottom sheet and standalone controller for ONVIF PTZ cameras.
class PtzBottomSheet extends ConsumerStatefulWidget {
  final Camera camera;

  const PtzBottomSheet({
    super.key,
    required this.camera,
  });

  static Future<void> show(BuildContext context, {required Camera camera}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PtzBottomSheet(camera: camera),
    );
  }

  @override
  ConsumerState<PtzBottomSheet> createState() => _PtzBottomSheetState();
}

class _PtzBottomSheetState extends ConsumerState<PtzBottomSheet> {
  List<PresetItem> _presets = [];
  bool _isLoadingPresets = true;
  String? _statusMessage;
  bool _isSuccessMessage = true;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final sdk = ref.read(hubsightSdkProvider);
    if (sdk == null) {
      if (mounted) setState(() => _isLoadingPresets = false);
      return;
    }

    try {
      final presets = await sdk.cameras.getPresets(widget.camera.id);
      if (mounted) {
        setState(() {
          _presets = presets;
          _isLoadingPresets = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load presets: $e');
      if (mounted) {
        setState(() => _isLoadingPresets = false);
      }
    }
  }

  Future<void> _handleAddNewPreset(AppLocalizations l10n) async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardAdaptive,
        shape: RoundedRectangleBorder(borderRadius: HubSightRadius.roundedXl),
        title: Row(
          children: [
            const Icon(Icons.bookmark_add_rounded, color: HubSightColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              l10n.addPreset,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimaryAdaptive),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.presetNamePrompt,
              style: TextStyle(fontSize: 13, color: context.textSecondaryAdaptive),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              autofocus: true,
              style: TextStyle(color: context.textPrimaryAdaptive),
              decoration: InputDecoration(
                hintText: 'e.g. Cổng chính, Cửa sổ, Sân sau',
                hintStyle: TextStyle(color: context.textMutedAdaptive),
                filled: true,
                fillColor: context.surfaceAdaptive,
                border: OutlineInputBorder(
                  borderRadius: HubSightRadius.roundedLg,
                  borderSide: BorderSide(color: context.borderAdaptive),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel, style: TextStyle(color: context.textSecondaryAdaptive)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: HubSightColors.primary,
              shape: RoundedRectangleBorder(borderRadius: HubSightRadius.roundedLg),
            ),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(ctx).pop(name);
              }
            },
            child: Text(l10n.addPreset, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final sdk = ref.read(hubsightSdkProvider);
      if (sdk == null) return;

      try {
        final newPreset = await sdk.cameras.setPreset(widget.camera.id, result);
        if (mounted) {
          setState(() {
            _presets.add(newPreset);
            _statusMessage = 'Đã lưu điểm nhớ: $result';
            _isSuccessMessage = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _statusMessage = 'Không thể lưu điểm nhớ: $e';
            _isSuccessMessage = false;
          });
        }
      }
    }
  }

  Future<void> _handleDeletePreset(PresetItem preset) async {
    final sdk = ref.read(hubsightSdkProvider);
    if (sdk == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardAdaptive,
        shape: RoundedRectangleBorder(borderRadius: HubSightRadius.roundedXl),
        title: Text(
          'Xóa điểm nhớ',
          style: TextStyle(color: context.textPrimaryAdaptive, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa điểm nhớ "${preset.name}" không?',
          style: TextStyle(color: context.textSecondaryAdaptive),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: HubSightColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await sdk.cameras.removePreset(widget.camera.id, preset.token);
        if (mounted) {
          setState(() {
            _presets.removeWhere((p) => p.token == preset.token);
            _statusMessage = 'Đã xóa điểm nhớ: ${preset.name}';
            _isSuccessMessage = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _statusMessage = 'Lỗi xóa điểm nhớ: $e';
            _isSuccessMessage = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sdk = ref.watch(hubsightSdkProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.cardAdaptive,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag pill
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: context.borderAdaptive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: HubSightColors.primary.withValues(alpha: 0.15),
                      borderRadius: HubSightRadius.roundedXl,
                    ),
                    child: const Icon(
                      Icons.control_camera_rounded,
                      color: HubSightColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l10n.ptzControl,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimaryAdaptive,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                              ),
                              child: const Text(
                                'ONVIF Profile S',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          widget.camera.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondaryAdaptive,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 14),

              // Status message banner if any
              if (_statusMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _isSuccessMessage
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : HubSightColors.errorBg,
                    borderRadius: HubSightRadius.roundedLg,
                    border: Border.all(
                      color: _isSuccessMessage
                          ? const Color(0xFF10B981).withValues(alpha: 0.3)
                          : HubSightColors.errorBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSuccessMessage ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                        size: 16,
                        color: _isSuccessMessage ? const Color(0xFF10B981) : HubSightColors.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _isSuccessMessage ? const Color(0xFF10B981) : HubSightColors.errorText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Central Touch PTZ D-Pad
              Center(
                child: HubSightPtzPad(
                  key: const Key('hubsight-ptz-dpad'),
                  cameraId: widget.camera.id,
                  cameraService: sdk?.cameras,
                  buttonSize: 50.0,
                  iconSize: 26.0,
                  spacing: 10.0,
                  padding: const EdgeInsets.all(16.0),
                  borderRadius: 24.0,
                  backgroundColor: context.surfaceAdaptive,
                  buttonColor: context.cardAdaptive,
                  buttonBorderColor: context.borderAdaptive,
                  iconColor: context.textPrimaryAdaptive,
                  stopButtonColor: HubSightColors.error.withValues(alpha: 0.2),
                  stopIconColor: HubSightColors.error,
                  onError: (e) {
                    if (mounted) {
                      setState(() {
                        _statusMessage = 'Lệnh PTZ không thành công: $e';
                        _isSuccessMessage = false;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 12),
              Text(
                'Nhấn giữ nút mũi tên để quay quét camera, thả tay để dừng.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: context.textMutedAdaptive,
                ),
              ),

              const SizedBox(height: 18),
              Divider(height: 1, color: context.borderAdaptive),
              const SizedBox(height: 12),

              // Presets Management Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bookmark_rounded, size: 16, color: context.textSecondaryAdaptive),
                      const SizedBox(width: 6),
                      Text(
                        l10n.presetsTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryAdaptive,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    key: const Key('add-preset-button'),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _handleAddNewPreset(l10n);
                    },
                    borderRadius: HubSightRadius.roundedLg,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: HubSightColors.primary.withValues(alpha: 0.12),
                        borderRadius: HubSightRadius.roundedLg,
                        border: Border.all(color: HubSightColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, size: 14, color: HubSightColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            l10n.addPreset,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: HubSightColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Presets Chips Carousel / List
              if (_isLoadingPresets) ...[
                const SizedBox(
                  height: 38,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: HubSightColors.primary),
                    ),
                  ),
                ),
              ] else if (_presets.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  child: Text(
                    'Chưa có điểm nhớ nào được lưu cho camera này.',
                    style: TextStyle(fontSize: 12, color: context.textMutedAdaptive),
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final preset = _presets[index];
                      return InkWell(
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          try {
                            await sdk?.cameras.gotoPreset(widget.camera.id, preset.token);
                            if (mounted) {
                              setState(() {
                                _statusMessage = 'Đang xoay camera tới: ${preset.name}';
                                _isSuccessMessage = true;
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                _statusMessage = 'Lỗi chuyển vị trí: $e';
                                _isSuccessMessage = false;
                              });
                            }
                          }
                        },
                        onLongPress: () => _handleDeletePreset(preset),
                        borderRadius: HubSightRadius.roundedLg,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.surfaceAdaptive,
                            borderRadius: HubSightRadius.roundedLg,
                            border: Border.all(color: context.borderAdaptive),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: HubSightColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                preset.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimaryAdaptive,
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _handleDeletePreset(preset),
                                child: Icon(Icons.close_rounded, size: 14, color: context.textMutedAdaptive),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
