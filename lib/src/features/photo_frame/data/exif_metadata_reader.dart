import 'dart:math' as math;
import 'dart:typed_data';

import 'package:exif_reader/exif_reader.dart';

import '../domain/photo_asset.dart';

class ExifMetadataReader {
  const ExifMetadataReader();

  Future<PhotoExif> read(Uint8List bytes) async {
    try {
      final exif = await readExifFromBytes(bytes);
      final tags = exif.tags;
      return PhotoExif(
        make: _clean(_tag(tags, 'Image Make')),
        model: _clean(_tag(tags, 'Image Model')),
        lens: _clean(
          _firstTag(tags, const ['EXIF LensModel', 'EXIF LensMake']),
        ),
        focalLength: _formatFocalLength(_tag(tags, 'EXIF FocalLength')),
        aperture: _formatAperture(
          _firstTag(tags, const ['EXIF FNumber', 'EXIF ApertureValue']),
        ),
        shutterSpeed: _formatShutter(
          _firstTag(tags, const [
            'EXIF ExposureTime',
            'EXIF ShutterSpeedValue',
          ]),
        ),
        iso: _formatIso(
          _firstTag(tags, const [
            'EXIF ISOSpeedRatings',
            'EXIF PhotographicSensitivity',
            'EXIF ISO',
          ]),
        ),
        dateTime: _formatDate(
          _firstTag(tags, const [
            'EXIF DateTimeOriginal',
            'EXIF DateTimeDigitized',
            'Image DateTime',
          ]),
        ),
        latitude: _formatGps(
          _tag(tags, 'GPS GPSLatitude'),
          _tag(tags, 'GPS GPSLatitudeRef'),
          positiveSuffix: 'N',
          negativeSuffix: 'S',
        ),
        longitude: _formatGps(
          _tag(tags, 'GPS GPSLongitude'),
          _tag(tags, 'GPS GPSLongitudeRef'),
          positiveSuffix: 'E',
          negativeSuffix: 'W',
        ),
      );
    } catch (_) {
      return const PhotoExif();
    }
  }

  static String? _tag(Map<String, IfdTag> tags, String name) {
    final value = tags[name]?.printable.trim();
    if (value == null || value.isEmpty || value == 'null') {
      return null;
    }
    return value;
  }

  static String? _firstTag(Map<String, IfdTag> tags, List<String> names) {
    for (final name in names) {
      final value = _tag(tags, name);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static String? _clean(String? value) {
    final text = value?.replaceAll('\u0000', '').trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  static String? _formatFocalLength(String? value) {
    final clean = _clean(value);
    if (clean == null) {
      return null;
    }
    final number = _numberFrom(clean);
    if (number == null) {
      return clean;
    }
    return '${_compactNumber(number)}mm';
  }

  static String? _formatAperture(String? value) {
    final clean = _clean(value);
    if (clean == null) {
      return null;
    }
    if (clean.toLowerCase().startsWith('f/')) {
      return clean;
    }
    if (clean.toLowerCase().startsWith('f')) {
      return 'f/${clean.substring(1).trim()}';
    }
    final number = _numberFrom(clean);
    if (number == null) {
      return clean;
    }
    return 'f/${_compactNumber(number)}';
  }

  static String? _formatShutter(String? value) {
    final clean = _clean(value);
    if (clean == null) {
      return null;
    }
    if (clean.endsWith('s')) {
      return clean;
    }
    if (clean.contains('/')) {
      return '${clean.replaceAll(' ', '')}s';
    }
    final number = _numberFrom(clean);
    if (number == null) {
      return clean;
    }
    if (number > 0 && number < 1) {
      final denominator = (1 / number).round();
      return '1/${denominator}s';
    }
    return '${_compactNumber(number)}s';
  }

  static String? _formatIso(String? value) {
    final clean = _clean(value);
    if (clean == null) {
      return null;
    }
    if (clean.toUpperCase().startsWith('ISO')) {
      return clean.replaceAll(' ', '');
    }
    final number = _numberFrom(clean);
    if (number == null) {
      return clean;
    }
    return 'ISO${number.round()}';
  }

  static String? _formatDate(String? value) {
    final clean = _clean(value);
    if (clean == null) {
      return null;
    }
    final match = RegExp(
      r'^(\d{4})[:\-](\d{2})[:\-](\d{2})\s+(\d{2}):(\d{2})',
    ).firstMatch(clean);
    if (match == null) {
      return clean;
    }
    return '${match.group(1)}.${match.group(2)}.${match.group(3)} '
        '${match.group(4)}:${match.group(5)}';
  }

  static String? _formatGps(
    String? value,
    String? ref, {
    required String positiveSuffix,
    required String negativeSuffix,
  }) {
    final clean = _clean(value);
    if (clean == null) {
      return null;
    }
    final nums = RegExp(r'-?\d+(?:\.\d+)?')
        .allMatches(clean)
        .map((match) => double.tryParse(match.group(0)!))
        .whereType<double>()
        .toList();
    if (nums.isEmpty) {
      return clean;
    }
    final degrees = nums.first;
    final minutes = nums.length > 1 ? nums[1] : 0;
    final seconds = nums.length > 2 ? nums[2] : 0;
    final suffix = ref?.toUpperCase().contains(negativeSuffix) == true
        ? negativeSuffix
        : positiveSuffix;
    final signedDegrees = suffix == negativeSuffix ? -degrees : degrees;
    final decimal = signedDegrees.abs() + minutes / 60 + seconds / 3600;
    return '${decimal.toStringAsFixed(5)}°$suffix';
  }

  static double? _numberFrom(String value) {
    final ratio = RegExp(
      r'(-?\d+(?:\.\d+)?)\s*/\s*(-?\d+(?:\.\d+)?)',
    ).firstMatch(value);
    if (ratio != null) {
      final numerator = double.tryParse(ratio.group(1)!);
      final denominator = double.tryParse(ratio.group(2)!);
      if (numerator != null && denominator != null && denominator != 0) {
        return numerator / denominator;
      }
    }
    final number = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(value);
    if (number == null) {
      return null;
    }
    return double.tryParse(number.group(0)!);
  }

  static String _compactNumber(double value) {
    if ((value - value.round()).abs() < 0.01) {
      return value.round().toString();
    }
    final precision = value < 10 ? 2 : 1;
    final scale = math.pow(10, precision).toDouble();
    final rounded = (value * scale).round() / scale;
    return rounded
        .toStringAsFixed(precision)
        .replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
