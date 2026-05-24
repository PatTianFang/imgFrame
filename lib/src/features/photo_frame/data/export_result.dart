enum ExportMode { fileSystem, browserDownload }

class ExportResult {
  const ExportResult({
    required this.count,
    required this.mode,
    required this.filePaths,
  });

  final int count;
  final ExportMode mode;
  final List<String> filePaths;

  String? get firstFilePath => filePaths.isEmpty ? null : filePaths.first;
}
