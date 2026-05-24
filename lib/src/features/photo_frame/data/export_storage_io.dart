import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

import 'export_result.dart';
import 'export_storage.dart';

class IoExportStorage implements ExportStorage {
  static const _androidExportChannel = MethodChannel('img_frame/export');

  @override
  Future<ExportResult> saveFiles({
    required List<ExportFilePayload> files,
    required String? directoryPath,
  }) async {
    if (Platform.isAndroid) {
      return _saveWithPlatformSaver(files);
    }

    final savedPaths = <String>[];
    for (final file in files) {
      final targetDirectory = directoryPath ?? file.fallbackDirectory;
      if (targetDirectory == null || targetDirectory.isEmpty) {
        throw StateError('无法确定导出目录，请先选择导出目录');
      }
      final directory = Directory(targetDirectory);
      await directory.create(recursive: true);
      final targetPath = path.join(directory.path, file.fileName);
      savedPaths.add(await _writeValidatedPng(targetPath, file.bytes));
    }
    return ExportResult(
      count: savedPaths.length,
      mode: ExportMode.fileSystem,
      filePaths: savedPaths,
    );
  }

  Future<ExportResult> _saveWithPlatformSaver(
    List<ExportFilePayload> files,
  ) async {
    final savedPaths = <String>[];
    for (final file in files) {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'img_frame_export_',
      );
      final tempFile = File(path.join(tempDirectory.path, file.fileName));
      try {
        _validatePngBytes(file.bytes);
        await tempFile.writeAsBytes(file.bytes);
        final savedPath = await _androidExportChannel.invokeMethod<String>(
          'savePng',
          <String, Object>{
            'fileName': file.fileName,
            'sourcePath': tempFile.path,
          },
        );
        if (savedPath == null || savedPath.isEmpty) {
          throw StateError('Android 系统保存失败，请检查相册或文件权限后重试');
        }
        savedPaths.add(savedPath);
      } finally {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      }
    }
    return ExportResult(
      count: savedPaths.length,
      mode: ExportMode.fileSystem,
      filePaths: savedPaths,
    );
  }

  Future<String> _writeValidatedPng(String targetPath, List<int> bytes) async {
    _validatePngBytes(bytes);
    final targetFile = File(targetPath);
    final tempFile = File(
      '$targetPath.tmp-${DateTime.now().microsecondsSinceEpoch}',
    );

    try {
      await tempFile.writeAsBytes(bytes);
      _validatePngBytes(await tempFile.readAsBytes());
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      final savedFile = await tempFile.rename(targetPath);
      return savedFile.path;
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  void _validatePngBytes(List<int> bytes) {
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    if (img.decodePng(data) == null) {
      throw StateError('导出的 PNG 文件校验失败，未写入损坏文件');
    }
  }
}

ExportStorage createExportStorage() => IoExportStorage();
