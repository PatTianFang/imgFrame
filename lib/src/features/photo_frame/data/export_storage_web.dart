import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

import 'export_result.dart';
import 'export_storage.dart';

class WebExportStorage implements ExportStorage {
  @override
  Future<ExportResult> saveFiles({
    required List<ExportFilePayload> files,
    required String? directoryPath,
  }) async {
    final savedNames = <String>[];
    for (final file in files) {
      await FileSaver.instance.saveFile(
        name: file.fileName.replaceFirst(RegExp(r'\.[^.]+$'), ''),
        bytes: Uint8List.fromList(file.bytes),
        fileExtension: 'png',
        mimeType: MimeType.png,
      );
      savedNames.add(file.fileName);
    }
    return ExportResult(
      count: savedNames.length,
      mode: ExportMode.browserDownload,
      filePaths: savedNames,
    );
  }
}

ExportStorage createExportStorage() => WebExportStorage();
