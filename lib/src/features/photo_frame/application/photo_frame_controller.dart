import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../data/export_progress.dart';
import '../data/export_result.dart';
import '../data/frame_settings_storage.dart';
import '../data/frame_export_service.dart';
import '../data/photo_import_service.dart';
import '../domain/frame_options.dart';
import '../domain/frame_style.dart';
import '../domain/photo_frame_settings.dart';
import '../domain/photo_asset.dart';

class PhotoFrameController extends ChangeNotifier {
  PhotoFrameController({
    PhotoImportService importService = const PhotoImportService(),
    FrameExportService? exportService,
    FrameSettingsStorage settingsStorage = const FrameSettingsStorage(),
  }) : _importService = importService,
       _exportService = exportService ?? FrameExportService(),
       _settingsStorage = settingsStorage;

  final PhotoImportService _importService;
  final FrameExportService _exportService;
  final FrameSettingsStorage _settingsStorage;

  final List<PhotoAsset> _photos = [];
  final Map<String, PhotoFrameSettings> _settingsByPhotoId = {};

  int _selectedIndex = 0;
  bool _isPicking = false;
  bool _isExporting = false;
  String? _exportDirectory;
  final ValueNotifier<ExportProgress?> _exportProgressNotifier = ValueNotifier(
    null,
  );

  List<PhotoAsset> get photos => List.unmodifiable(_photos);
  PhotoFrameSettings get settings {
    final photo = selectedPhoto;
    if (photo == null) {
      return const PhotoFrameSettings();
    }
    return _settingsFor(photo);
  }

  FrameStyle get style => settings.style;
  FrameOptions get frameOptions => settings.options;
  int get selectedIndex => _selectedIndex;
  bool get isPicking => _isPicking;
  bool get isExporting => _isExporting;
  ExportProgress? get exportProgress => _exportProgressNotifier.value;
  ValueListenable<ExportProgress?> get exportProgressListenable =>
      _exportProgressNotifier;
  bool get hasPhotos => _photos.isNotEmpty;
  bool get canChooseExportDirectory {
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  String? get exportDirectory => _exportDirectory;
  bool get usesCustomExportDirectory =>
      _exportDirectory != null && _exportDirectory!.isNotEmpty;

  PhotoAsset? get selectedPhoto {
    if (_photos.isEmpty) {
      return null;
    }
    return _photos[_selectedIndex.clamp(0, _photos.length - 1).toInt()];
  }

  String get exportLocationLabel {
    if (kIsWeb) {
      return '浏览器默认下载目录';
    }
    if (!canChooseExportDirectory) {
      return '系统默认保存位置';
    }
    if (usesCustomExportDirectory) {
      return _exportDirectory!;
    }
    final directories = _sourceDirectories;
    if (directories.isEmpty) {
      return '请先选择导出目录';
    }
    if (directories.length == 1) {
      return '${directories.first}（原图同目录）';
    }
    return '每张照片导出到各自原图所在目录';
  }

  String get exportLocationHint {
    if (kIsWeb) {
      return '浏览器版本不支持固定导出目录，导出文件会进入浏览器下载列表。';
    }
    if (!canChooseExportDirectory) {
      return '移动端会调用系统保存能力，导出的照片会进入系统默认位置。';
    }
    if (usesCustomExportDirectory) {
      return '当前已固定导出到所选目录。';
    }
    return '未单独设置时，默认导出到原图所在目录。';
  }

  Future<String> importPhotos() async {
    _setPicking(true);
    try {
      final picked = await _importService.pickPhotos();
      if (picked.isEmpty) {
        return '未选择照片';
      }
      final wasEmpty = _photos.isEmpty;
      _photos.addAll(picked);
      for (final photo in picked) {
        _settingsByPhotoId.putIfAbsent(
          photo.id,
          () => const PhotoFrameSettings(),
        );
      }
      if (wasEmpty) {
        _selectedIndex = 0;
      }
      notifyListeners();
      return '已导入 ${picked.length} 张照片';
    } catch (error) {
      return '导入失败：$error';
    } finally {
      _setPicking(false);
    }
  }

  Future<String> chooseExportDirectory() async {
    if (!canChooseExportDirectory) {
      return kIsWeb
          ? '浏览器版本不支持固定导出目录，文件会下载到浏览器默认下载目录'
          : '当前平台使用系统默认保存位置，不支持固定导出目录';
    }
    try {
      final directory = await _pickExportDirectory();
      if (directory == null || directory.isEmpty) {
        return '未更改导出目录';
      }
      _exportDirectory = directory;
      notifyListeners();
      return '导出目录已设置为 $directory';
    } catch (error) {
      return '选择导出目录失败：$error';
    }
  }

  Future<String?> _pickExportDirectory() async {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return FilePicker.getDirectoryPath(dialogTitle: '选择导出目录');
    }

    try {
      return await FilePicker.getDirectoryPath(
        dialogTitle: '选择导出目录',
        initialDirectory: selectedPhoto?.sourceDirectory,
        lockParentWindow: true,
      );
    } catch (_) {
      return FilePicker.getDirectoryPath(dialogTitle: '选择导出目录');
    }
  }

  void resetExportDirectory() {
    _exportDirectory = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _exportProgressNotifier.dispose();
    super.dispose();
  }

  void selectPhoto(int index) {
    if (_photos.isEmpty) {
      return;
    }
    _selectedIndex = index.clamp(0, _photos.length - 1).toInt();
    notifyListeners();
  }

  void setStyle(FrameStyle style) {
    _updateSelectedSettings((settings) => settings.copyWith(style: style));
  }

  void setFrameOptions(FrameOptions options) {
    _updateSelectedSettings((settings) => settings.copyWith(options: options));
  }

  void setDeviceNameOverride(String value) {
    setFrameOptions(frameOptions.copyWith(deviceNameOverride: value));
  }

  String applySelectedSettingsToAll() {
    final photo = selectedPhoto;
    if (photo == null) {
      return '没有可应用的照片参数';
    }
    final selectedSettings = _settingsFor(photo);
    for (final target in _photos) {
      _settingsByPhotoId[target.id] = selectedSettings;
    }
    notifyListeners();
    return '已将当前照片参数应用到 ${_photos.length} 张照片';
  }

  Future<String> saveCurrentSettings() async {
    final photo = selectedPhoto;
    if (photo == null) {
      return '没有可保存的照片参数';
    }
    try {
      await _settingsStorage.save(_settingsFor(photo));
      return '已保存当前照片参数配置';
    } catch (error) {
      return '保存配置失败：$error';
    }
  }

  Future<String> loadSavedSettings() async {
    final photo = selectedPhoto;
    if (photo == null) {
      return '没有可加载配置的照片';
    }
    try {
      final saved = await _settingsStorage.load();
      if (saved == null) {
        return '还没有保存过配置';
      }
      _settingsByPhotoId[photo.id] = saved;
      notifyListeners();
      return '已加载配置到当前照片';
    } catch (error) {
      return '加载配置失败：$error';
    }
  }

  void removeSelected() {
    if (_photos.isEmpty) {
      return;
    }
    final removed = _photos.removeAt(_selectedIndex);
    _settingsByPhotoId.remove(removed.id);
    if (_photos.isEmpty) {
      _selectedIndex = 0;
    } else if (_selectedIndex >= _photos.length) {
      _selectedIndex = _photos.length - 1;
    }
    notifyListeners();
  }

  Future<String> exportSelected() async {
    final photo = selectedPhoto;
    if (photo == null) {
      return '没有可导出的照片';
    }
    final photoSettings = _settingsFor(photo);
    _startExporting(totalPhotos: 1);
    try {
      final result = await _exportService.exportOne(
        photo,
        photoSettings.style,
        options: photoSettings.options,
        directoryPath: _exportDirectory,
        onProgress: _setExportProgress,
      );
      return _buildExportMessage(result);
    } on StateError catch (error) {
      return error.message;
    } catch (error) {
      return '导出失败：$error';
    } finally {
      _finishExporting();
    }
  }

  Future<String> exportAll() async {
    if (_photos.isEmpty) {
      return '没有可导出的照片';
    }
    final photos = List<PhotoAsset>.of(_photos);
    _startExporting(totalPhotos: photos.length);
    try {
      final result = await _exportService.exportItems(
        [
          for (final photo in photos)
            PhotoExportItem(photo: photo, settings: _settingsFor(photo)),
        ],
        directoryPath: _exportDirectory,
        onProgress: _setExportProgress,
      );
      return _buildExportMessage(result);
    } on StateError catch (error) {
      return error.message;
    } catch (error) {
      return '导出失败：$error';
    } finally {
      _finishExporting();
    }
  }

  Set<String> get _sourceDirectories =>
      _photos.map((photo) => photo.sourceDirectory).whereType<String>().toSet();

  PhotoFrameSettings _settingsFor(PhotoAsset photo) {
    return _settingsByPhotoId.putIfAbsent(
      photo.id,
      () => const PhotoFrameSettings(),
    );
  }

  void _updateSelectedSettings(
    PhotoFrameSettings Function(PhotoFrameSettings settings) update,
  ) {
    final photo = selectedPhoto;
    if (photo == null) {
      return;
    }
    _settingsByPhotoId[photo.id] = update(_settingsFor(photo));
    notifyListeners();
  }

  String _buildExportMessage(ExportResult result) {
    if (result.mode == ExportMode.browserDownload) {
      return '已生成 ${result.count} 张照片，请在浏览器下载记录中查看';
    }
    if (result.count == 1 && result.firstFilePath != null) {
      return '已导出到 ${result.firstFilePath}';
    }
    final directories = result.filePaths.map(path.dirname).toSet();
    if (directories.length == 1) {
      return '已导出 ${result.count} 张照片到 ${directories.first}';
    }
    return '已导出 ${result.count} 张照片到各自原图所在目录';
  }

  void _setPicking(bool value) {
    _isPicking = value;
    notifyListeners();
  }

  void _startExporting({required int totalPhotos}) {
    _isExporting = true;
    _exportProgressNotifier.value = ExportProgress(
      currentPhoto: 1,
      totalPhotos: totalPhotos,
      currentPercent: 0,
      phase: '准备导出',
    );
    notifyListeners();
  }

  void _setExportProgress(ExportProgress progress) {
    _exportProgressNotifier.value = progress;
  }

  void _finishExporting() {
    _isExporting = false;
    _exportProgressNotifier.value = null;
    notifyListeners();
  }
}
