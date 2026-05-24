import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../data/export_result.dart';
import '../data/frame_export_service.dart';
import '../data/photo_import_service.dart';
import '../domain/frame_style.dart';
import '../domain/photo_asset.dart';

class PhotoFrameController extends ChangeNotifier {
  PhotoFrameController({
    PhotoImportService importService = const PhotoImportService(),
    FrameExportService? exportService,
  }) : _importService = importService,
       _exportService = exportService ?? FrameExportService();

  final PhotoImportService _importService;
  final FrameExportService _exportService;

  final List<PhotoAsset> _photos = [];

  FrameStyle _style = FrameStyle.softGlow;
  int _selectedIndex = 0;
  bool _isPicking = false;
  bool _isExporting = false;
  String? _exportDirectory;

  List<PhotoAsset> get photos => List.unmodifiable(_photos);
  FrameStyle get style => _style;
  int get selectedIndex => _selectedIndex;
  bool get isPicking => _isPicking;
  bool get isExporting => _isExporting;
  bool get hasPhotos => _photos.isNotEmpty;
  bool get canChooseExportDirectory => !kIsWeb;
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
    if (kIsWeb) {
      return '浏览器版本不支持固定导出目录，文件会下载到浏览器默认下载目录';
    }
    try {
      final directory = await FilePicker.getDirectoryPath(
        dialogTitle: '选择导出目录',
        initialDirectory: selectedPhoto?.sourceDirectory,
        lockParentWindow: true,
      );
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

  void resetExportDirectory() {
    _exportDirectory = null;
    notifyListeners();
  }

  void selectPhoto(int index) {
    if (_photos.isEmpty) {
      return;
    }
    _selectedIndex = index.clamp(0, _photos.length - 1).toInt();
    notifyListeners();
  }

  void setStyle(FrameStyle style) {
    _style = style;
    notifyListeners();
  }

  void removeSelected() {
    if (_photos.isEmpty) {
      return;
    }
    _photos.removeAt(_selectedIndex);
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
    _setExporting(true);
    try {
      final result = await _exportService.exportOne(
        photo,
        _style,
        directoryPath: _exportDirectory,
      );
      return _buildExportMessage(result);
    } on StateError catch (error) {
      return error.message;
    } catch (error) {
      return '导出失败：$error';
    } finally {
      _setExporting(false);
    }
  }

  Future<String> exportAll() async {
    if (_photos.isEmpty) {
      return '没有可导出的照片';
    }
    _setExporting(true);
    try {
      final result = await _exportService.exportAll(
        _photos,
        _style,
        directoryPath: _exportDirectory,
      );
      return _buildExportMessage(result);
    } on StateError catch (error) {
      return error.message;
    } catch (error) {
      return '导出失败：$error';
    } finally {
      _setExporting(false);
    }
  }

  Set<String> get _sourceDirectories =>
      _photos.map((photo) => photo.sourceDirectory).whereType<String>().toSet();

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

  void _setExporting(bool value) {
    _isExporting = value;
    notifyListeners();
  }
}
