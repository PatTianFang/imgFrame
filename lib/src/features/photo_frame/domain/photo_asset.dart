import 'dart:typed_data';

class PhotoAsset {
  const PhotoAsset({
    required this.id,
    required this.name,
    required this.bytes,
    required this.width,
    required this.height,
    required this.exif,
    this.sourcePath,
  });

  final String id;
  final String name;
  final Uint8List bytes;
  final int width;
  final int height;
  final PhotoExif exif;
  final String? sourcePath;

  double get aspectRatio => width <= 0 || height <= 0 ? 4 / 3 : width / height;

  String? get sourceDirectory {
    final path = sourcePath;
    if (path == null || path.isEmpty) {
      return null;
    }
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    if (index <= 0) {
      return null;
    }
    return normalized.substring(0, index);
  }
}

class PhotoExif {
  const PhotoExif({
    this.make,
    this.model,
    this.lens,
    this.focalLength,
    this.aperture,
    this.shutterSpeed,
    this.iso,
    this.dateTime,
    this.latitude,
    this.longitude,
  });

  final String? make;
  final String? model;
  final String? lens;
  final String? focalLength;
  final String? aperture;
  final String? shutterSpeed;
  final String? iso;
  final String? dateTime;
  final String? latitude;
  final String? longitude;

  String get cameraLine {
    final parts = [
      cameraBodyLine,
      if (lens != null && lens!.isNotEmpty) lens,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'Unknown Camera' : parts.join(' ');
  }

  String get cameraBodyLine =>
      _joinMakeAndModel(make, model) ?? 'Unknown Camera';

  String get lensLine =>
      lens == null || lens!.isEmpty ? 'Lens unavailable' : lens!;

  String get exposureLine {
    final parts = [
      focalLength,
      aperture,
      shutterSpeed,
      iso,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'No EXIF exposure data' : parts.join('  ');
  }

  String get compactExposureLine {
    final parts = [
      focalLength,
      aperture,
      shutterSpeed,
      iso,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'EXIF unavailable' : parts.join('  ');
  }

  String get dateLine => dateTime ?? 'Date unavailable';

  String get locationLine {
    if (latitude == null || longitude == null) {
      return 'Location unavailable';
    }
    return '$latitude  $longitude';
  }

  Map<String, String?> toMap() {
    return {
      'make': make,
      'model': model,
      'lens': lens,
      'focalLength': focalLength,
      'aperture': aperture,
      'shutterSpeed': shutterSpeed,
      'iso': iso,
      'dateTime': dateTime,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory PhotoExif.fromMap(Map<String, Object?> map) {
    return PhotoExif(
      make: map['make'] as String?,
      model: map['model'] as String?,
      lens: map['lens'] as String?,
      focalLength: map['focalLength'] as String?,
      aperture: map['aperture'] as String?,
      shutterSpeed: map['shutterSpeed'] as String?,
      iso: map['iso'] as String?,
      dateTime: map['dateTime'] as String?,
      latitude: map['latitude'] as String?,
      longitude: map['longitude'] as String?,
    );
  }

  static String? _joinMakeAndModel(String? make, String? model) {
    final cleanMake = make?.trim();
    final cleanModel = model?.trim();
    if ((cleanMake == null || cleanMake.isEmpty) &&
        (cleanModel == null || cleanModel.isEmpty)) {
      return null;
    }
    if (cleanMake == null || cleanMake.isEmpty) {
      return cleanModel;
    }
    if (cleanModel == null || cleanModel.isEmpty) {
      return cleanMake;
    }
    if (cleanModel.toLowerCase().startsWith(cleanMake.toLowerCase())) {
      return cleanModel;
    }
    return '$cleanMake $cleanModel';
  }
}
