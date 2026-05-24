import 'export_result.dart';
import 'export_storage_stub.dart'
    if (dart.library.io) 'export_storage_io.dart'
    if (dart.library.js_interop) 'export_storage_web.dart'
    as storage;

abstract class ExportStorage {
  Future<ExportResult> saveFiles({
    required List<ExportFilePayload> files,
    required String? directoryPath,
  });
}

class ExportFilePayload {
  const ExportFilePayload({
    required this.fileName,
    required this.bytes,
    this.fallbackDirectory,
  });

  final String fileName;
  final List<int> bytes;
  final String? fallbackDirectory;
}

ExportStorage createExportStorage() => storage.createExportStorage();
