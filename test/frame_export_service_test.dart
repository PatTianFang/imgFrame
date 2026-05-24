import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:img_frame/src/features/photo_frame/data/export_result.dart';
import 'package:img_frame/src/features/photo_frame/data/export_storage.dart';
import 'package:img_frame/src/features/photo_frame/data/frame_export_service.dart';
import 'package:img_frame/src/features/photo_frame/domain/frame_options.dart';
import 'package:img_frame/src/features/photo_frame/domain/frame_style.dart';
import 'package:img_frame/src/features/photo_frame/domain/photo_asset.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exports a rendered PNG for each frame style', () async {
    final storage = _RecordingExportStorage();
    final service = FrameExportService(storage: storage);
    final photo = _samplePhoto();

    for (final style in FrameStyle.values) {
      final result = await service
          .exportOne(photo, style, directoryPath: r'C:\exports')
          .timeout(const Duration(seconds: 15));

      expect(result.count, 1);
      expect(result.mode, ExportMode.fileSystem);
      expect(storage.files.last.fileName, 'sample_${style.fileSuffix}.png');
      expect(storage.files.last.bytes.take(8), _pngSignature);
      final rendered = img.decodePng(
        Uint8List.fromList(storage.files.last.bytes),
      );
      expect(rendered, isNotNull);
      expect(rendered!.width, isNot(1440));
      if (style == FrameStyle.whiteInfo) {
        expect(rendered.width, photo.width);
        expect(rendered.height, greaterThan(photo.height));
        final sourcePixel = rendered.getPixel(0, 0);
        expect(sourcePixel.r, 82);
        expect(sourcePixel.g, 124);
        expect(sourcePixel.b, 168);
      } else {
        expect(rendered.width, greaterThan(photo.width));
        expect(rendered.height, greaterThan(photo.height));
      }
    }
  });

  test(
    'reports photo count and current-photo percent while exporting',
    () async {
      final service = FrameExportService(storage: _RecordingExportStorage());
      final singleProgress = <String>[];

      await service.exportOne(
        _samplePhoto(),
        FrameStyle.whiteInfo,
        directoryPath: r'C:\exports',
        onProgress: (progress) {
          singleProgress.add(
            '${progress.photoProgressLabel}:${progress.currentPercentLabel}',
          );
        },
      );

      expect(singleProgress.first, '1/1:0%');
      expect(singleProgress, contains('1/1:5%'));
      expect(singleProgress, contains('1/1:85%'));
      expect(singleProgress, contains('1/1:100%'));

      final batchProgress = <String>[];
      await service.exportAll(
        [
          _samplePhoto(id: 'sample-1', name: 'sample-1.jpg'),
          _samplePhoto(id: 'sample-2', name: 'sample-2.jpg'),
        ],
        FrameStyle.softGlow,
        directoryPath: r'C:\exports',
        onProgress: (progress) {
          batchProgress.add(
            '${progress.photoProgressLabel}:${progress.currentPercentLabel}',
          );
        },
      );

      expect(batchProgress, contains('1/2:0%'));
      expect(batchProgress, contains('1/2:100%'));
      expect(batchProgress, contains('2/2:0%'));
      expect(batchProgress.last, '2/2:100%');
    },
  );

  test('applies custom frame options during export', () async {
    final storage = _RecordingExportStorage();
    final service = FrameExportService(storage: storage);
    final photo = _samplePhoto();

    await service.exportOne(
      photo,
      FrameStyle.softGlow,
      directoryPath: r'C:\exports',
    );
    final defaultImage = img.decodePng(
      Uint8List.fromList(storage.files.last.bytes),
    );

    await service.exportOne(
      photo,
      FrameStyle.softGlow,
      options: const FrameOptions(
        borderScale: 1.6,
        logoScale: 1.4,
        textScale: 1.25,
        badgeAlignment: LeicaBadgeAlignment.left,
        visibleInfoFields: {
          FrameInfoField.focalLength,
          FrameInfoField.aperture,
        },
      ),
      directoryPath: r'C:\exports',
    );
    final customImage = img.decodePng(
      Uint8List.fromList(storage.files.last.bytes),
    );

    expect(defaultImage, isNotNull);
    expect(customImage, isNotNull);
    expect(customImage!.width, greaterThan(defaultImage!.width));
    expect(customImage.height, greaterThan(defaultImage.height));
  });
}

PhotoAsset _samplePhoto({String id = 'sample', String name = 'sample.jpg'}) {
  return PhotoAsset(
    id: id,
    name: name,
    bytes: _samplePngBytes(),
    width: _sampleWidth,
    height: _sampleHeight,
    exif: const PhotoExif(
      make: 'Leica',
      model: 'M11',
      lens: 'Summilux 35',
      focalLength: '35mm',
      aperture: 'f/1.4',
      shutterSpeed: '1/125s',
      iso: 'ISO200',
      dateTime: '2026.05.24 12:00',
    ),
    sourcePath: 'C:\\photos\\$name',
  );
}

Uint8List _samplePngBytes() {
  final image = img.Image(width: _sampleWidth, height: _sampleHeight);
  img.fill(image, color: img.ColorRgb8(82, 124, 168));
  return Uint8List.fromList(img.encodePng(image));
}

const _sampleWidth = 160;
const _sampleHeight = 100;
const _pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];

class _RecordingExportStorage implements ExportStorage {
  final files = <ExportFilePayload>[];

  @override
  Future<ExportResult> saveFiles({
    required List<ExportFilePayload> files,
    required String? directoryPath,
  }) async {
    this.files.addAll(files);
    return ExportResult(
      count: files.length,
      mode: ExportMode.fileSystem,
      filePaths: [
        for (final file in files) '${directoryPath ?? ''}\\${file.fileName}',
      ],
    );
  }
}
