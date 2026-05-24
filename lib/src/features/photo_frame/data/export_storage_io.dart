import 'dart:io';

import 'package:path/path.dart' as path;

import 'export_result.dart';
import 'export_storage.dart';

class IoExportStorage implements ExportStorage {
  @override
  Future<ExportResult> saveFiles({
    required List<ExportFilePayload> files,
    required String? directoryPath,
  }) async {
    final savedPaths = <String>[];
    for (final file in files) {
      final targetDirectory = directoryPath ?? file.fallbackDirectory;
      if (targetDirectory == null || targetDirectory.isEmpty) {
        throw StateError('无法确定导出目录，请先选择导出目录');
      }
      final directory = Directory(targetDirectory);
      await directory.create(recursive: true);
      final targetPath = path.join(directory.path, file.fileName);
      final targetFile = File(targetPath);
      await targetFile.writeAsBytes(file.bytes, flush: true);
      savedPaths.add(targetFile.path);
    }
    return ExportResult(
      count: savedPaths.length,
      mode: ExportMode.fileSystem,
      filePaths: savedPaths,
    );
  }
}

ExportStorage createExportStorage() => IoExportStorage();
