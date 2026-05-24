class ExportProgress {
  const ExportProgress({
    required this.currentPhoto,
    required this.totalPhotos,
    required this.currentPercent,
    required this.phase,
  });

  final int currentPhoto;
  final int totalPhotos;
  final int currentPercent;
  final String phase;

  double get progressValue => currentPercent.clamp(0, 100) / 100;

  String get photoProgressLabel => '$currentPhoto/$totalPhotos';

  String get currentPercentLabel => '${currentPercent.clamp(0, 100)}%';
}

typedef ExportProgressCallback = void Function(ExportProgress progress);
