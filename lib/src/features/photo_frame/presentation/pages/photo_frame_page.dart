import 'package:flutter/material.dart';

import '../../application/photo_frame_controller.dart';
import '../../data/export_progress.dart';
import '../../domain/frame_options.dart';
import '../../domain/frame_style.dart';
import '../widgets/empty_state.dart';
import '../widgets/exif_panel.dart';
import '../widgets/export_location_panel.dart';
import '../widgets/photo_gallery.dart';
import '../widgets/photo_preview.dart';
import '../widgets/style_selector.dart';

class PhotoFramePage extends StatefulWidget {
  const PhotoFramePage({super.key});

  @override
  State<PhotoFramePage> createState() => _PhotoFramePageState();
}

class _PhotoFramePageState extends State<PhotoFramePage> {
  late final PhotoFrameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PhotoFrameController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 980;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 24,
            title: const Text('imgFrame'),
            actions: [
              IconButton(
                tooltip: '关于',
                onPressed: _showAbout,
                icon: const Icon(Icons.info_outline),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.icon(
                  onPressed: _controller.isPicking || _controller.isExporting
                      ? null
                      : _onImport,
                  icon: _controller.isPicking
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(_controller.hasPhotos ? '继续导入' : '导入照片'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: IconButton.filledTonal(
                  tooltip: '批量导出',
                  onPressed: !_controller.hasPhotos || _controller.isExporting
                      ? null
                      : _onExportAll,
                  icon: _controller.isExporting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_download_outlined),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _controller.isExporting
              ? ValueListenableBuilder<ExportProgress?>(
                  valueListenable: _controller.exportProgressListenable,
                  builder: (context, progress, _) {
                    if (progress == null) {
                      return const SizedBox.shrink();
                    }
                    return _ExportProgressDock(progress: progress);
                  },
                )
              : null,
          body: SafeArea(
            child: !_controller.hasPhotos
                ? EmptyState(onPick: _controller.isPicking ? null : _onImport)
                : isWide
                ? _WideLayout(
                    controller: _controller,
                    onSelectPhoto: _controller.selectPhoto,
                    onStyleChanged: _controller.setStyle,
                    onFrameOptionsChanged: _controller.setFrameOptions,
                    onChooseExportDirectory: _onChooseExportDirectory,
                    onResetExportDirectory: _controller.resetExportDirectory,
                    onSaveSettings: _onSaveSettings,
                    onLoadSettings: _onLoadSettings,
                    onApplySettingsToAll: _onApplySettingsToAll,
                    onExportSelected: _onExportSelected,
                    onRemoveSelected: _controller.removeSelected,
                  )
                : _CompactLayout(
                    controller: _controller,
                    onSelectPhoto: _controller.selectPhoto,
                    onStyleChanged: _controller.setStyle,
                    onFrameOptionsChanged: _controller.setFrameOptions,
                    onChooseExportDirectory: _onChooseExportDirectory,
                    onResetExportDirectory: _controller.resetExportDirectory,
                    onSaveSettings: _onSaveSettings,
                    onLoadSettings: _onLoadSettings,
                    onApplySettingsToAll: _onApplySettingsToAll,
                    onExportSelected: _onExportSelected,
                    onRemoveSelected: _controller.removeSelected,
                  ),
          ),
        );
      },
    );
  }

  Future<void> _onImport() async {
    final message = await _controller.importPhotos();
    if (!mounted) {
      return;
    }
    _showMessage(message);
  }

  Future<void> _onChooseExportDirectory() async {
    final message = await _controller.chooseExportDirectory();
    if (!mounted) {
      return;
    }
    _showMessage(message);
  }

  Future<void> _onExportSelected() async {
    final message = await _controller.exportSelected();
    if (!mounted) {
      return;
    }
    _showMessage(message);
  }

  Future<void> _onExportAll() async {
    final message = await _controller.exportAll();
    if (!mounted) {
      return;
    }
    _showMessage(message);
  }

  Future<void> _onSaveSettings() async {
    final message = await _controller.saveCurrentSettings();
    if (!mounted) {
      return;
    }
    _showMessage(message);
  }

  Future<void> _onLoadSettings() async {
    final message = await _controller.loadSavedSettings();
    if (!mounted) {
      return;
    }
    _showMessage(message);
  }

  void _onApplySettingsToAll() {
    _showMessage(_controller.applySelectedSettingsToAll());
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'imgFrame',
      applicationVersion: '1.0',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset('assets/branding/logo.png', width: 56, height: 56),
      ),
      children: const [
        SizedBox(height: 8),
        SelectableText('作者：埃及猪肉'),
        SizedBox(height: 6),
        SelectableText('GitHub：https://github.com/PatTianFang'),
        SizedBox(height: 6),
        SelectableText('邮箱：PatTianFang@outlook.com'),
      ],
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.controller,
    required this.onSelectPhoto,
    required this.onStyleChanged,
    required this.onFrameOptionsChanged,
    required this.onChooseExportDirectory,
    required this.onResetExportDirectory,
    required this.onSaveSettings,
    required this.onLoadSettings,
    required this.onApplySettingsToAll,
    required this.onExportSelected,
    required this.onRemoveSelected,
  });

  final PhotoFrameController controller;
  final ValueChanged<int> onSelectPhoto;
  final ValueChanged<FrameStyle> onStyleChanged;
  final ValueChanged<FrameOptions> onFrameOptionsChanged;
  final VoidCallback onChooseExportDirectory;
  final VoidCallback onResetExportDirectory;
  final Future<void> Function() onSaveSettings;
  final Future<void> Function() onLoadSettings;
  final VoidCallback onApplySettingsToAll;
  final VoidCallback onExportSelected;
  final VoidCallback onRemoveSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 304,
          child: PhotoGallery(
            photos: controller.photos,
            selectedIndex: controller.selectedIndex,
            horizontal: false,
            onSelected: onSelectPhoto,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: PhotoPreview(
              photo: controller.selectedPhoto!,
              style: controller.style,
              options: controller.frameOptions,
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(
          width: 360,
          child: _Inspector(
            controller: controller,
            onStyleChanged: onStyleChanged,
            onFrameOptionsChanged: onFrameOptionsChanged,
            onChooseExportDirectory: onChooseExportDirectory,
            onResetExportDirectory: onResetExportDirectory,
            onSaveSettings: onSaveSettings,
            onLoadSettings: onLoadSettings,
            onApplySettingsToAll: onApplySettingsToAll,
            onExportSelected: onExportSelected,
            onRemoveSelected: onRemoveSelected,
          ),
        ),
      ],
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({
    required this.controller,
    required this.onSelectPhoto,
    required this.onStyleChanged,
    required this.onFrameOptionsChanged,
    required this.onChooseExportDirectory,
    required this.onResetExportDirectory,
    required this.onSaveSettings,
    required this.onLoadSettings,
    required this.onApplySettingsToAll,
    required this.onExportSelected,
    required this.onRemoveSelected,
  });

  final PhotoFrameController controller;
  final ValueChanged<int> onSelectPhoto;
  final ValueChanged<FrameStyle> onStyleChanged;
  final ValueChanged<FrameOptions> onFrameOptionsChanged;
  final VoidCallback onChooseExportDirectory;
  final VoidCallback onResetExportDirectory;
  final Future<void> Function() onSaveSettings;
  final Future<void> Function() onLoadSettings;
  final VoidCallback onApplySettingsToAll;
  final VoidCallback onExportSelected;
  final VoidCallback onRemoveSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 116,
          child: PhotoGallery(
            photos: controller.photos,
            selectedIndex: controller.selectedIndex,
            horizontal: true,
            onSelected: onSelectPhoto,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.56,
          child: PhotoPreview(
            photo: controller.selectedPhoto!,
            style: controller.style,
            options: controller.frameOptions,
          ),
        ),
        const SizedBox(height: 16),
        _Inspector(
          controller: controller,
          scrollable: false,
          padding: EdgeInsets.zero,
          onStyleChanged: onStyleChanged,
          onFrameOptionsChanged: onFrameOptionsChanged,
          onChooseExportDirectory: onChooseExportDirectory,
          onResetExportDirectory: onResetExportDirectory,
          onSaveSettings: onSaveSettings,
          onLoadSettings: onLoadSettings,
          onApplySettingsToAll: onApplySettingsToAll,
          onExportSelected: onExportSelected,
          onRemoveSelected: onRemoveSelected,
        ),
      ],
    );
  }
}

class _Inspector extends StatelessWidget {
  const _Inspector({
    required this.controller,
    required this.onStyleChanged,
    required this.onFrameOptionsChanged,
    required this.onChooseExportDirectory,
    required this.onResetExportDirectory,
    required this.onSaveSettings,
    required this.onLoadSettings,
    required this.onApplySettingsToAll,
    required this.onExportSelected,
    required this.onRemoveSelected,
    this.scrollable = true,
    this.padding = const EdgeInsets.all(24),
  });

  final PhotoFrameController controller;
  final ValueChanged<FrameStyle> onStyleChanged;
  final ValueChanged<FrameOptions> onFrameOptionsChanged;
  final VoidCallback onChooseExportDirectory;
  final VoidCallback onResetExportDirectory;
  final Future<void> Function() onSaveSettings;
  final Future<void> Function() onLoadSettings;
  final VoidCallback onApplySettingsToAll;
  final VoidCallback onExportSelected;
  final VoidCallback onRemoveSelected;
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final photo = controller.selectedPhoto!;
    final children = [
      Text(
        photo.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 6),
      Text(
        '${photo.width} × ${photo.height}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 24),
      StyleSelector(value: controller.style, onChanged: onStyleChanged),
      const SizedBox(height: 24),
      _FrameOptionsPanel(
        options: controller.frameOptions,
        onChanged: onFrameOptionsChanged,
      ),
      const SizedBox(height: 24),
      _SettingsActionsPanel(
        isExporting: controller.isExporting,
        onSaveSettings: onSaveSettings,
        onLoadSettings: onLoadSettings,
        onApplySettingsToAll: onApplySettingsToAll,
      ),
      const SizedBox(height: 24),
      ExportLocationPanel(
        locationLabel: controller.exportLocationLabel,
        locationHint: controller.exportLocationHint,
        canChooseDirectory: controller.canChooseExportDirectory,
        usesCustomDirectory: controller.usesCustomExportDirectory,
        onChooseDirectory: onChooseExportDirectory,
        onResetDirectory: onResetExportDirectory,
      ),
      const SizedBox(height: 24),
      ExifPanel(exif: photo.exif),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: controller.isExporting ? null : onExportSelected,
        icon: controller.isExporting
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download_outlined),
        label: const Text('导出当前照片'),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: controller.isExporting ? null : onRemoveSelected,
        icon: const Icon(Icons.delete_outline),
        label: const Text('移出列表'),
      ),
    ];
    if (scrollable) {
      return ListView(padding: padding, children: children);
    }
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _FrameOptionsPanel extends StatelessWidget {
  const _FrameOptionsPanel({required this.options, required this.onChanged});

  final FrameOptions options;
  final ValueChanged<FrameOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.border_outer_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('边框设置', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 16),
            _DeviceNameField(
              value: options.deviceNameOverride,
              onChanged: (value) {
                onChanged(options.copyWith(deviceNameOverride: value));
              },
            ),
            const SizedBox(height: 16),
            _ScaleSlider(
              label: '边框大小',
              value: options.normalizedBorderScale,
              min: 0.65,
              max: 1.8,
              onChanged: (value) {
                onChanged(options.copyWith(borderScale: value));
              },
            ),
            _ScaleSlider(
              label: '图标大小',
              value: options.normalizedLogoScale,
              min: 0.6,
              max: 1.8,
              onChanged: (value) {
                onChanged(options.copyWith(logoScale: value));
              },
            ),
            _ScaleSlider(
              label: '信息字号',
              value: options.normalizedTextScale,
              min: 0.75,
              max: 1.65,
              onChanged: (value) {
                onChanged(options.copyWith(textScale: value));
              },
            ),
            const SizedBox(height: 12),
            Text('徕卡标位置', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<LeicaBadgeAlignment>(
                segments: [
                  for (final alignment in LeicaBadgeAlignment.values)
                    ButtonSegment(
                      value: alignment,
                      label: Text(alignment.label),
                    ),
                ],
                selected: {options.badgeAlignment},
                showSelectedIcon: false,
                onSelectionChanged: (selected) {
                  onChanged(options.copyWith(badgeAlignment: selected.first));
                },
              ),
            ),
            const SizedBox(height: 16),
            Text('显示信息', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final field in FrameInfoField.values)
                  FilterChip(
                    label: Text(field.label),
                    selected: options.visibleInfoFields.contains(field),
                    onSelected: (selected) {
                      final fields = Set<FrameInfoField>.of(
                        options.visibleInfoFields,
                      );
                      if (selected) {
                        fields.add(field);
                      } else {
                        fields.remove(field);
                      }
                      onChanged(options.copyWith(visibleInfoFields: fields));
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceNameField extends StatefulWidget {
  const _DeviceNameField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_DeviceNameField> createState() => _DeviceNameFieldState();
}

class _DeviceNameFieldState extends State<_DeviceNameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _DeviceNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        labelText: '自定义设备名称',
        hintText: '留空使用 EXIF 设备名称',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.photo_camera_outlined),
      ),
      textInputAction: TextInputAction.done,
      onChanged: widget.onChanged,
    );
  }
}

class _SettingsActionsPanel extends StatelessWidget {
  const _SettingsActionsPanel({
    required this.isExporting,
    required this.onSaveSettings,
    required this.onLoadSettings,
    required this.onApplySettingsToAll,
  });

  final bool isExporting;
  final Future<void> Function() onSaveSettings;
  final Future<void> Function() onLoadSettings;
  final VoidCallback onApplySettingsToAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.save_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('配置操作', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: isExporting ? null : onSaveSettings,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('保存当前配置'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: isExporting ? null : onLoadSettings,
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('加载已保存配置'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: isExporting ? null : onApplySettingsToAll,
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('应用当前参数到全部照片'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleSlider extends StatelessWidget {
  const _ScaleSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.labelLarge)),
              Text(
                '${(value * 100).round()}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: 24,
            label: '${(value * 100).round()}%',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ExportProgressDock extends StatelessWidget {
  const _ExportProgressDock({required this.progress});

  final ExportProgress progress;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;
    return Material(
      elevation: 10,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 12 : 24,
            10,
            isCompact ? 12 : 24,
            isCompact ? 12 : 16,
          ),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: _ExportProgressPanel(progress: progress),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExportProgressPanel extends StatelessWidget {
  const _ExportProgressPanel({required this.progress});

  final ExportProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox.square(
                  dimension: 38,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress.progressValue,
                        strokeWidth: 3.2,
                      ),
                      Icon(
                        Icons.file_download_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '正在导出',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              child: Text(
                                progress.photoProgressLabel,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        progress.phase,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  progress.currentPercentLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.progressValue,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
            ),
          ],
        ),
      ),
    );
  }
}
