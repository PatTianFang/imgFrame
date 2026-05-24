import 'export_result.dart';
import 'export_storage.dart';

class UnsupportedExportStorage implements ExportStorage {
  @override
  Future<ExportResult> saveFiles({
    required List<ExportFilePayload> files,
    required String? directoryPath,
  }) {
    throw UnsupportedError('当前平台不支持文件系统导出');
  }
}

ExportStorage createExportStorage() => UnsupportedExportStorage();
