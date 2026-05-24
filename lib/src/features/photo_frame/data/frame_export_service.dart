import '../domain/frame_style.dart';
import '../domain/photo_asset.dart';
import 'export_result.dart';
import 'export_storage.dart';
import 'frame_renderer.dart';

class FrameExportService {
  FrameExportService({ExportStorage? storage})
    : _storage = storage ?? createExportStorage();

  final ExportStorage _storage;

  Future<ExportResult> exportOne(
    PhotoAsset photo,
    FrameStyle style, {
    String? directoryPath,
  }) async {
    final bytes = await FrameRenderer.render(photo, style);
    return _storage.saveFiles(
      files: [
        ExportFilePayload(
          fileName: _fileName(photo, style),
          bytes: bytes,
          fallbackDirectory: photo.sourceDirectory,
        ),
      ],
      directoryPath: directoryPath,
    );
  }

  Future<ExportResult> exportAll(
    List<PhotoAsset> photos,
    FrameStyle style, {
    String? directoryPath,
  }) async {
    final files = <ExportFilePayload>[];
    for (final photo in photos) {
      final bytes = await FrameRenderer.render(photo, style);
      files.add(
        ExportFilePayload(
          fileName: _fileName(photo, style),
          bytes: bytes,
          fallbackDirectory: photo.sourceDirectory,
        ),
      );
    }
    return _storage.saveFiles(files: files, directoryPath: directoryPath);
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
