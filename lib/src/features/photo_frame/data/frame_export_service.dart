import 'dart:async';

import '../domain/frame_options.dart';
import '../domain/frame_style.dart';
import '../domain/photo_frame_settings.dart';
import '../domain/photo_asset.dart';
import 'export_progress.dart';
import 'export_result.dart';
import 'export_storage.dart';
import 'frame_renderer.dart';

class FrameExportService {
  FrameExportService({ExportStorage? storage})
    : _storage = storage ?? createExportStorage();

  static const _renderTimeout = Duration(minutes: 5);
  static const _saveTimeout = Duration(minutes: 2);

  final ExportStorage _storage;

  Future<ExportResult> exportOne(
    PhotoAsset photo,
    FrameStyle style, {
    FrameOptions options = const FrameOptions(),
    String? directoryPath,
    ExportProgressCallback? onProgress,
  }) async {
    return _exportPhoto(
      photo,
      style,
      options: options,
      currentPhoto: 1,
      totalPhotos: 1,
      directoryPath: directoryPath,
      onProgress: onProgress,
    );
  }

  Future<ExportResult> exportAll(
    List<PhotoAsset> photos,
    FrameStyle style, {
    FrameOptions options = const FrameOptions(),
    String? directoryPath,
    ExportProgressCallback? onProgress,
  }) async {
    final filePaths = <String>[];
    ExportMode? mode;
    for (var index = 0; index < photos.length; index++) {
      final result = await _exportPhoto(
        photos[index],
        style,
        options: options,
        currentPhoto: index + 1,
        totalPhotos: photos.length,
        directoryPath: directoryPath,
        onProgress: onProgress,
      );
      mode ??= result.mode;
      filePaths.addAll(result.filePaths);
    }
    return ExportResult(
      count: filePaths.length,
      mode: mode ?? ExportMode.fileSystem,
      filePaths: filePaths,
    );
  }

  Future<ExportResult> exportItems(
    List<PhotoExportItem> items, {
    String? directoryPath,
    ExportProgressCallback? onProgress,
  }) async {
    final filePaths = <String>[];
    ExportMode? mode;
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final result = await _exportPhoto(
        item.photo,
        item.settings.style,
        options: item.settings.options,
        currentPhoto: index + 1,
        totalPhotos: items.length,
        directoryPath: directoryPath,
        onProgress: onProgress,
      );
      mode ??= result.mode;
      filePaths.addAll(result.filePaths);
    }
    return ExportResult(
      count: filePaths.length,
      mode: mode ?? ExportMode.fileSystem,
      filePaths: filePaths,
    );
  }

  Future<ExportResult> _exportPhoto(
    PhotoAsset photo,
    FrameStyle style, {
    required FrameOptions options,
    required int currentPhoto,
    required int totalPhotos,
    required String? directoryPath,
    required ExportProgressCallback? onProgress,
  }) async {
    _emitProgress(onProgress, currentPhoto, totalPhotos, 0, '准备导出');
    final bytes = await _runWithProgress(
      () => _render(photo, style, options),
      currentPhoto: currentPhoto,
      totalPhotos: totalPhotos,
      startPercent: 5,
      endPercent: 85,
      phase: '正在合成照片',
      onProgress: onProgress,
    );
    final result = await _runWithProgress(
      () => _save(
        files: [
          ExportFilePayload(
            fileName: _fileName(photo, style),
            bytes: bytes,
            fallbackDirectory: photo.sourceDirectory,
          ),
        ],
        directoryPath: directoryPath,
      ),
      currentPhoto: currentPhoto,
      totalPhotos: totalPhotos,
      startPercent: 86,
      endPercent: 99,
      phase: '正在保存文件',
      onProgress: onProgress,
    );
    _emitProgress(onProgress, currentPhoto, totalPhotos, 100, '已完成');
    return result;
  }

  Future<T> _runWithProgress<T>(
    Future<T> Function() action, {
    required int currentPhoto,
    required int totalPhotos,
    required int startPercent,
    required int endPercent,
    required String phase,
    required ExportProgressCallback? onProgress,
  }) async {
    _emitProgress(onProgress, currentPhoto, totalPhotos, startPercent, phase);
    if (onProgress == null) {
      final result = await action();
      _emitProgress(onProgress, currentPhoto, totalPhotos, endPercent, phase);
      return result;
    }

    var percent = startPercent;
    final maxBeforeDone = endPercent - 1;
    final timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (percent >= maxBeforeDone) {
        return;
      }
      final remaining = maxBeforeDone - percent;
      final step = remaining <= 3 ? 1 : (remaining / 8).ceil();
      percent += step;
      if (percent > maxBeforeDone) {
        percent = maxBeforeDone;
      }
      _emitProgress(onProgress, currentPhoto, totalPhotos, percent, phase);
    });

    try {
      final result = await action();
      _emitProgress(onProgress, currentPhoto, totalPhotos, endPercent, phase);
      return result;
    } finally {
      timer.cancel();
    }
  }

  void _emitProgress(
    ExportProgressCallback? onProgress,
    int currentPhoto,
    int totalPhotos,
    int currentPercent,
    String phase,
  ) {
    onProgress?.call(
      ExportProgress(
        currentPhoto: currentPhoto,
        totalPhotos: totalPhotos,
        currentPercent: currentPercent,
        phase: phase,
      ),
    );
  }

  Future<List<int>> _render(
    PhotoAsset photo,
    FrameStyle style,
    FrameOptions options,
  ) {
    return FrameRenderer.render(photo, style, options: options).timeout(
      _renderTimeout,
      onTimeout: () => throw StateError('导出渲染超时，请尝试缩小照片或减少批量数量'),
    );
  }

  Future<ExportResult> _save({
    required List<ExportFilePayload> files,
    required String? directoryPath,
  }) {
    return _storage
        .saveFiles(files: files, directoryPath: directoryPath)
        .timeout(
          _saveTimeout,
          onTimeout: () => throw StateError('保存文件超时，请检查导出目录权限后重试'),
        );
  }

  String _fileName(PhotoAsset photo, FrameStyle style) {
    final baseName = photo.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
    final clean = baseName.replaceAll(
      RegExp(r'[^a-zA-Z0-9_\-\u4e00-\u9fa5]'),
      '_',
    );
    return '${clean}_${style.fileSuffix}.png';
  }
}

class PhotoExportItem {
  const PhotoExportItem({required this.photo, required this.settings});

  final PhotoAsset photo;
  final PhotoFrameSettings settings;
}
