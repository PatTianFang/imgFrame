import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:img_frame/src/features/photo_frame/application/photo_frame_controller.dart';
import 'package:img_frame/src/features/photo_frame/data/export_result.dart';
import 'package:img_frame/src/features/photo_frame/data/export_storage.dart';
import 'package:img_frame/src/features/photo_frame/data/frame_export_service.dart';
import 'package:img_frame/src/features/photo_frame/data/frame_settings_storage.dart';
import 'package:img_frame/src/features/photo_frame/data/photo_import_service.dart';
import 'package:img_frame/src/features/photo_frame/domain/frame_options.dart';
import 'package:img_frame/src/features/photo_frame/domain/frame_style.dart';
import 'package:img_frame/src/features/photo_frame/domain/photo_asset.dart';
import 'package:img_frame/src/features/photo_frame/domain/photo_frame_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keeps frame settings independent per imported photo', () async {
    final controller = PhotoFrameController(
      importService: _FakePhotoImportService([
        _samplePhoto(id: 'photo-1', name: 'photo-1.jpg'),
        _samplePhoto(id: 'photo-2', name: 'photo-2.jpg'),
      ]),
      settingsStorage: _MemoryFrameSettingsStorage(),
    );

    await controller.importPhotos();
    controller
      ..setStyle(FrameStyle.whiteInfo)
      ..setFrameOptions(
        const FrameOptions(
          borderScale: 1.4,
          deviceNameOverride: 'Leica Q3 Custom',
        ),
      );

    controller.selectPhoto(1);
    expect(controller.style, FrameStyle.softGlow);
    expect(controller.frameOptions.borderScale, 1);
    expect(controller.frameOptions.deviceNameOverride, isEmpty);

    controller.setDeviceNameOverride('Second Camera');
    expect(controller.frameOptions.deviceNameOverride, 'Second Camera');

    controller.selectPhoto(0);
    expect(controller.style, FrameStyle.whiteInfo);
    expect(controller.frameOptions.borderScale, 1.4);
    expect(controller.frameOptions.deviceNameOverride, 'Leica Q3 Custom');

    final message = controller.applySelectedSettingsToAll();
    expect(message, '已将当前照片参数应用到 2 张照片');

    controller.selectPhoto(1);
    expect(controller.style, FrameStyle.whiteInfo);
    expect(controller.frameOptions.borderScale, 1.4);
    expect(controller.frameOptions.deviceNameOverride, 'Leica Q3 Custom');

    controller.dispose();
  });

  test('saves and loads the selected photo settings', () async {
    final storage = _MemoryFrameSettingsStorage();
    final controller = PhotoFrameController(
      importService: _FakePhotoImportService([_samplePhoto()]),
      settingsStorage: storage,
    );

    await controller.importPhotos();
    controller
      ..setStyle(FrameStyle.whiteInfo)
      ..setFrameOptions(
        const FrameOptions(
          logoScale: 1.5,
          textScale: 1.2,
          deviceNameOverride: 'Saved Camera',
        ),
      );

    expect(await controller.saveCurrentSettings(), '已保存当前照片参数配置');

    controller
      ..setStyle(FrameStyle.softGlow)
      ..setFrameOptions(const FrameOptions(deviceNameOverride: 'Changed'));

    expect(await controller.loadSavedSettings(), '已加载配置到当前照片');
    expect(controller.style, FrameStyle.whiteInfo);
    expect(controller.frameOptions.logoScale, 1.5);
    expect(controller.frameOptions.textScale, 1.2);
    expect(controller.frameOptions.deviceNameOverride, 'Saved Camera');

    controller.dispose();
  });

  test('exports all photos with their own settings', () async {
    final exportStorage = _RecordingExportStorage();
    final controller = PhotoFrameController(
      importService: _FakePhotoImportService([
        _samplePhoto(id: 'photo-1', name: 'photo-1.jpg'),
        _samplePhoto(id: 'photo-2', name: 'photo-2.jpg'),
      ]),
      exportService: FrameExportService(storage: exportStorage),
      settingsStorage: _MemoryFrameSettingsStorage(),
    );

    await controller.importPhotos();
    controller.setStyle(FrameStyle.whiteInfo);
    controller.selectPhoto(1);
    controller.setStyle(FrameStyle.softGlow);

    final message = await controller.exportAll();

    expect(message, contains('已导出 2 张照片'));
    expect(exportStorage.files[0].fileName, 'photo-1_white-info.png');
    expect(exportStorage.files[1].fileName, 'photo-2_soft-glow.png');

    controller.dispose();
  });
}

PhotoAsset _samplePhoto({String id = 'photo', String name = 'photo.jpg'}) {
  return PhotoAsset(
    id: id,
    name: name,
    bytes: _samplePngBytes(),
    width: 120,
    height: 80,
    exif: const PhotoExif(
      make: 'Leica',
      model: 'Q3',
      focalLength: '28mm',
      aperture: 'f/1.7',
      shutterSpeed: '1/250s',
      iso: 'ISO100',
      dateTime: '2026.05.24 12:00',
    ),
    sourcePath: 'C:\\photos\\$name',
  );
}

Uint8List _samplePngBytes() {
  final image = img.Image(width: 120, height: 80);
  img.fill(image, color: img.ColorRgb8(80, 120, 160));
  return Uint8List.fromList(img.encodePng(image));
}

class _FakePhotoImportService extends PhotoImportService {
  const _FakePhotoImportService(this.photos);

  final List<PhotoAsset> photos;

  @override
  Future<List<PhotoAsset>> pickPhotos() async {
    return photos;
  }
}

class _MemoryFrameSettingsStorage extends FrameSettingsStorage {
  PhotoFrameSettings? saved;

  @override
  Future<void> save(PhotoFrameSettings settings) async {
    saved = settings;
  }

  @override
  Future<PhotoFrameSettings?> load() async {
    return saved;
  }
}

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
        for (final file in files)
          '${directoryPath ?? 'C:\\exports'}\\${file.fileName}',
      ],
    );
  }
}
