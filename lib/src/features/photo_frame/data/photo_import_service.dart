import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

import '../domain/photo_asset.dart';
import 'exif_metadata_reader.dart';

class PhotoImportService {
  const PhotoImportService({
    ExifMetadataReader reader = const ExifMetadataReader(),
  }) : _reader = reader;

  final ExifMetadataReader _reader;

  Future<List<PhotoAsset>> pickPhotos() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return const [];
    }

    final photos = <PhotoAsset>[];
    final batchId = DateTime.now().microsecondsSinceEpoch;
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        continue;
      }
      final size = _readImageSize(bytes);
      final exif = await _reader.read(bytes);
      photos.add(
        PhotoAsset(
          id: '${file.name}-${file.size}-$batchId-${photos.length}',
          name: file.name,
          bytes: bytes,
          width: size.$1,
          height: size.$2,
          exif: exif,
          sourcePath: file.path,
        ),
      );
    }
    return photos;
  }

  (int width, int height) _readImageSize(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return (1, 1);
    }
    final oriented = img.bakeOrientation(decoded);
    return (oriented.width, oriented.height);
  }
}
