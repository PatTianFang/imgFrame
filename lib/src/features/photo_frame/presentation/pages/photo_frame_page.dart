import 'package:flutter/material.dart';

import '../../application/photo_frame_controller.dart';
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
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.icon(
                  onPressed: _controller.isPicking ? null : _onImport,
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
          body: SafeArea(
            child: !_controller.hasPhotos
                ? EmptyState(onPick: _controller.isPicking ? null : _onImport)
                : isWide
                ? _WideLayout(
                    controller: _controller,
                    onSelectPhoto: _controller.selectPhoto,
                    onStyleChanged: _controller.setStyle,
                    onChooseExportDirectory: _onChooseExportDirectory,
                    onResetExportDirectory: _controller.resetExportDirectory,
                    onExportSelected: _onExportSelected,
                    onRemoveSelected: _controller.removeSelected,
                  )
                : _CompactLayout(
                    controller: _controller,
                    onSelectPhoto: _controller.selectPhoto,
                    onStyleChanged: _controller.setStyle,
                    onChooseExportDirectory: _onChooseExportDirectory,
                    onResetExportDirectory: _controller.resetExportDirectory,
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
    required this.onChooseExportDirectory,
    required this.onResetExportDirectory,
    required this.onExportSelected,
    required this.onRemoveSelected,
  });

  final PhotoFrameController controller;
  final ValueChanged<int> onSelectPhoto;
  final ValueChanged<FrameStyle> onStyleChanged;
  final VoidCallback onChooseExportDirectory;
  final VoidCallback onResetExportDirectory;
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
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(
          width: 360,
          child: _Inspector(
            controller: controller,
            onStyleChanged: onStyleChanged,
            onChooseExportDirectory: onChooseExportDirectory,
            onResetExportDirectory: onResetExportDirectory,
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
    required this.onChooseExportDirectory,
    required this.onResetExportDirectory,
    required this.onExportSelected,
    required this.onRemoveSelected,
  });

  final PhotoFrameController controller;
  final ValueChanged<int> onSelectPhoto;
  final ValueChanged<FrameStyle> onStyleChanged;
  final VoidCallback onChooseExportDirectory;
  final VoidCallback onResetExportDirectory;
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
          ),
        ),
        const SizedBox(height: 16),
        _Inspector(
          controller: controller,
          onStyleChanged: onStyleChanged,
          onChooseExportDirectory: onChooseExportDirectory,
          onResetExportDirectory: onResetExportDirectory,
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
    required this.onChooseExportDirectory,
    required this.onResetExportDirectory,
    required this.onExportSelected,
    required this.onRemoveSelected,
  });

  final PhotoFrameController controller;
  final ValueChanged<FrameStyle> onStyleChanged;
  final VoidCallback onChooseExportDirectory;
  final VoidCallback onResetExportDirectory;
  final VoidCallback onExportSelected;
  final VoidCallback onRemoveSelected;

  @override
  Widget build(BuildContext context) {
    final photo = controller.selectedPhoto!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
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
          onPressed: onRemoveSelected,
          icon: const Icon(Icons.delete_outline),
          label: const Text('移出列表'),
        ),
      ],
    );
  }
}
