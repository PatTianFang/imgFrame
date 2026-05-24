# imgFrame

imgFrame 是一个基于 Flutter 的多端照片边框工具。它面向摄影照片整理和社交平台发图场景，支持一次导入多张图片，自动读取 EXIF 参数，并生成带相机信息、焦距、光圈、快门和 ISO 的成品图。

## 当前能力

- 多图导入：支持 `jpg`、`jpeg`、`png`、`webp`。
- EXIF 解析：读取相机厂商、机型、镜头、焦距、光圈、快门、ISO、拍摄时间、GPS。
- 两种边框样式：
  - 沉浸柔光：照片模糊背景、主体圆角卡片、底部居中参数。
  - 白底信息栏：照片主体加底部白色信息栏，左侧相机与时间，右侧 Leica 标识、参数与坐标。
- 批量处理：同一批照片共享当前边框样式，一键批量导出。
- 导出位置：
  - Windows 默认导出到原图所在目录。
  - 可手动选择固定导出目录。
  - 浏览器版本受浏览器安全限制，导出到浏览器默认下载目录。
- 多端目标：Flutter Android、Windows 已接入工程，后续可继续补齐 iOS、macOS、Linux、Web。

## 技术路线

项目采用 Flutter + Material 3。UI 侧使用 Flutter 原生组件完成响应式布局；文件选择、EXIF 解析、图片合成和文件保存分别由独立基础设施服务负责，避免 UI 直接耦合第三方插件。

核心依赖：

- `file_picker`：跨平台选择多张图片。
- `exif_reader`：从图片字节中读取 EXIF，支持 JPEG、PNG、WebP、HEIC 等格式的元数据解析能力。
- `image`：在 Dart 层完成导出图离屏合成，包括缩放、裁剪、模糊、圆角、文字和标识绘制。
- `file_saver`：保存导出的 PNG 文件。

## 实现思路

导入流程：

1. 用户通过文件选择器一次选择多张图片。
2. 应用读取图片字节并用 `image` 解码尺寸，同时用 `exif_reader` 解析 EXIF。
3. EXIF 原始字段统一格式化为 `PhotoExif`，例如 `200mm`、`f/2.96`、`1/25s`、`ISO640`。
4. 页面状态由 `PhotoFrameController` 管理，UI 只负责展示和触发命令。

导出流程：

1. 用户选择边框样式。
2. 用户可选择固定导出目录；未设置时，桌面端默认回写到原图所在目录。
3. `FrameRenderer` 在后台 isolate 中按样式生成固定宽度 PNG，减少导出时主界面卡顿。
4. 沉浸柔光样式先生成铺满画布的模糊背景，再叠加圆角主图和底部参数。
5. 白底信息栏样式按参考图生成照片主体和底部白色信息栏。
6. Windows 端直接写入目标目录；Web 端触发浏览器下载。

## 工程结构

```text
lib/
  main.dart
  src/
    app/
      app.dart
      app_theme.dart
    features/
      photo_frame/
        application/
          photo_frame_controller.dart
        data/
          exif_metadata_reader.dart
          frame_export_service.dart
          frame_renderer.dart
          photo_import_service.dart
        domain/
          frame_style.dart
          photo_asset.dart
        presentation/
          pages/
            photo_frame_page.dart
          widgets/
            empty_state.dart
            exif_panel.dart
            photo_gallery.dart
            photo_preview.dart
            style_selector.dart
```

分层说明：

- `app`：应用入口、主题、全局 Material 配置。
- `domain`：业务实体和值对象，不依赖 Flutter 插件。
- `data`：第三方插件和图片处理实现。
- `application`：页面状态和用例编排。
- `presentation`：页面与组件。

## 工程报告

本阶段完成了从空目录到可运行 Flutter 工程的搭建，并将早期平铺代码重构为按功能模块组织的结构。项目当前重点是照片边框主流程，因此采用单 feature 模块 `photo_frame`，后续如果增加模板市场、历史记录、批量队列或用户预设，可以按相同结构继续扩展。

当前质量状态：

- `flutter analyze`：通过。
- `flutter test`：通过。
- Windows Release：已验证可构建。
- Android Release：已验证可构建，产物为 `dist/imgFrame-android-release.apk`。

主要设计取舍：

- 导出图使用 Dart `image` 包离屏合成，减少平台原生差异，便于 Android、Windows、Web 等端复用。
- 预览图使用 Flutter Widget 实时渲染，保证交互流畅；导出图由 `FrameRenderer` 重新生成高分辨率 PNG，保证输出质量。
- 状态管理暂用 `ChangeNotifier`，当前复杂度较低；当后续出现模板编辑、任务队列、配置持久化时，可以迁移到 Riverpod 或 Bloc。

## 技术报告

EXIF 字段兼容策略：

- EXIF 不同品牌字段名不完全一致，读取时会按候选字段顺序兜底。
- 参数格式化统一在 `ExifMetadataReader` 内完成，避免 UI 到处处理 `Ratio`、空值和品牌重复名。
- GPS 输出为 `纬度°N/S 经度°E/W`，当前仅展示，不做地图逆地理编码。

渲染策略：

- 导出画布固定宽度 `1440px`，高度根据原图比例和边框信息区动态计算。
- 主图缩放使用 cubic 插值。
- 沉浸柔光样式使用背景 cover 裁剪、Gaussian Blur、半透明遮罩和圆角主体。
- 白底信息栏样式使用固定底栏高度，便于信息对齐和批量输出风格统一。

风险与后续优化：

- `image` 内置位图字体主要覆盖 ASCII，导出图中的中文文本当前会回退或被裁剪；如要在导出图片中完整绘制中文，建议后续接入 TTF 字体渲染方案。
- 大批量超高像素照片在移动端可能有内存压力，后续可改为流式读取、后台 isolate 渲染和队列进度展示。
- Leica 标识当前是参考风格的视觉占位，不应作为官方商标资源分发；商业发布前建议替换为用户可配置 Logo 或自有品牌标识。

## 开发环境

推荐环境：

- Flutter `3.44.0` 或更新稳定版。
- Dart `3.12.0` 或 Flutter 自带版本。
- Windows 构建：Visual Studio 2026，启用 Desktop development with C++。
- Android 构建：Android Studio 或 Android Command-line Tools，安装 Android SDK、Platform SDK、Build Tools 并接受 SDK 许可证。本机已验证配置为 Android Studio `D:\Android\Android Studio`、JDK `D:\Android\Android Studio\jbr`、Android SDK `C:\Users\PatTi\AppData\Local\Android\sdk`。

## 常用命令

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d windows
flutter build windows --release
flutter build apk --release
```

如果 Flutter 未加入 PATH，可使用本机 SDK 绝对路径：

```powershell
& 'D:\flutter\flutter\bin\flutter.bat' analyze
& 'D:\flutter\flutter\bin\flutter.bat' build windows --release
```

## Android 打包

本项目当前 Android 构建使用 Android Gradle Plugin `8.13.1` 和 Kotlin Gradle Plugin `2.3.20`。由于项目位于 `F:` 盘，而 Windows 默认 Pub cache 通常位于 `C:` 盘，Kotlin 增量编译可能遇到跨盘相对路径问题；建议 Android 打包时使用项目内的本地 Pub cache。

首次构建前确认 Android SDK 和许可证：

```powershell
$env:JAVA_HOME = 'D:\Android\Android Studio\jbr'
$env:ANDROID_HOME = 'C:\Users\PatTi\AppData\Local\Android\sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME

& 'D:\Flutter\flutter\bin\flutter.bat' doctor -v
& "$env:ANDROID_HOME\cmdline-tools\latest\bin\sdkmanager.bat" --licenses
```

打包 APK：

```powershell
$env:JAVA_HOME = 'D:\Android\Android Studio\jbr'
$env:ANDROID_HOME = 'C:\Users\PatTi\AppData\Local\Android\sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:PUB_CACHE = "$PWD\.tools\pub-cache"

& 'D:\Flutter\flutter\bin\flutter.bat' pub get
& 'D:\Flutter\flutter\bin\flutter.bat' build apk --release

New-Item -ItemType Directory -Force -Path 'dist' | Out-Null
Copy-Item -LiteralPath 'build\app\outputs\flutter-apk\app-release.apk' -Destination 'dist\imgFrame-android-release.apk' -Force
```

如果本机默认 Pub cache 已经下载过依赖，也可以先同步到项目内缓存，减少重新下载时间：

```powershell
robocopy "$env:LOCALAPPDATA\Pub\Cache" "$PWD\.tools\pub-cache" /E /MT:16 /R:2 /W:2 /XD _temp
```

当前 APK 使用 `android/app/build.gradle.kts` 中的 debug 签名配置，仅适合本地安装测试。上架应用商店前应配置正式签名，并使用 App Bundle：

```powershell
& 'D:\Flutter\flutter\bin\flutter.bat' build appbundle --release
```

## 构建产物

Windows Release 构建后，应用目录位于：

```text
build/windows/x64/runner/Release/
```

其中 `img_frame.exe` 需要和同目录下的 DLL、`data/` 文件夹一起分发。

Windows 构建如果提示缺少 symlink support，需要开启系统开发者模式：

```powershell
start ms-settings:developers
```

Android Release 构建后，APK 默认位于：

```text
build/app/outputs/flutter-apk/app-release.apk
```

复制到分发目录后的 APK 位于：

```text
dist/imgFrame-android-release.apk
```

本次已实际生成：

```text
build/web
build/windows/x64/runner/Release
build/app/outputs/flutter-apk/app-release.apk
dist/imgFrame-web.zip
dist/imgFrame-windows-x64.zip
dist/imgFrame-android-release.apk
```

本仓库提供了便携工具链安装脚本，会把 JDK 和 Android SDK 下载到 `.tools/`，不写入仓库：

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\install_android_toolchain.ps1
```

该脚本需要能访问 Adoptium 和 Google Android Repository。
