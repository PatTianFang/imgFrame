# imgFrame

imgFrame 是一个基于 Flutter 的多端照片边框工具。当前版本为 `1.0.0+1`，软件内显示版本 `1.0`。它面向摄影照片整理和社交平台发图场景，支持一次导入多张图片，自动读取 EXIF 参数，并生成带相机信息、焦距、光圈、快门和 ISO 的成品图。

## 当前能力

- 多图导入：支持 `jpg`、`jpeg`、`png`、`webp`。
- EXIF 解析：读取相机厂商、机型、镜头、焦距、光圈、快门、ISO、拍摄时间、GPS。
- 两种边框样式：
  - 沉浸柔光：照片模糊背景、主体圆角卡片、底部参数与 Leica 标识。
  - 白底信息栏：照片主体加底部信息栏，展示相机、镜头、曝光、时间和位置等信息。
- 边框配置：支持调整边框大小、图标大小、边框信息字号、Leica 标识左/中/右位置，以及相机、镜头、焦距、光圈、快门、ISO、时间、位置等字段的显示与隐藏。
- 设备名称覆盖：可以手动指定边框里显示的设备名称，覆盖 EXIF 读取到的机型名。
- 预览一致性：预览和导出共用同一套布局计算，尽量保证屏幕预览和最终 PNG 的相对布局、边距、Logo 位置和信息排布一致。
- 批量处理：同一批照片共享当前边框样式和边框配置，一键批量导出。
- 独立参数：每张导入图片都有自己的样式和边框配置，切换选中图片时只会修改当前图片，不会影响其他图片。
- 配置保存：支持保存当前选中图片的配置，并重新加载到当前图片；还可以一键把当前参数应用到全部照片。
- 响应式界面：Windows、Android、Web 使用同一套功能面板；手机端改为纵向滚动布局，保留桌面端的样式、边框、字段、导出和 EXIF 功能。
- 导出位置：
  - Windows 默认导出到原图所在目录，也可手动选择固定导出目录。
  - Android 通过原生 `MediaStore` 保存到系统相册/图片目录 `Pictures/imgFrame`，避免第三方保存插件回调卡住导致导出一直转圈。
  - 浏览器版本受浏览器安全限制，导出到浏览器默认下载目录。
- 导出进度：底部进度面板显示当前照片序号、当前阶段和百分比，手机端使用更紧凑的进度布局。
- 软件图标：根目录原始 `logo.png`、`logo.ico` 已移动到工程资源目录，并用于应用内展示、Windows 图标、Android 启动图标和 Web 图标。
- 关于界面：应用栏提供关于入口，展示版本、作者、GitHub 和邮箱。
- 多端目标：Flutter Android、Windows、Web 已接入工程并验证 Release 构建，后续可继续补齐 iOS、macOS、Linux。

## 关于

- 作者：埃及猪肉
- GitHub：<https://github.com/PatTianFang>
- 邮箱：<PatTianFang@outlook.com>

## 技术路线

项目采用 Flutter + Material 3。UI 侧使用 Flutter 原生组件完成响应式布局；文件选择、EXIF 解析、图片合成和文件保存分别由独立基础设施服务负责，避免 UI 直接耦合第三方插件。

核心依赖：

- `file_picker`：跨平台选择多张图片。
- `exif_reader`：从图片字节中读取 EXIF，支持 JPEG、PNG、WebP、HEIC 等格式的元数据解析能力。
- `image`：在 Dart 层完成导出图离屏合成，包括背景处理、裁剪、模糊、圆角、文字和标识绘制。
- `path_drawing`：在预览层绘制 Leica 矢量标识路径。
- `file_saver`：用于 Web 端触发浏览器下载。
- `shared_preferences`：保存用户当前边框配置，供后续加载到当前图片。

## 实现思路

导入流程：

1. 用户通过文件选择器一次选择多张图片。
2. 应用读取图片字节并用 `image` 解码尺寸，同时用 `exif_reader` 解析 EXIF。
3. EXIF 原始字段统一格式化为 `PhotoExif`，例如 `200mm`、`f/2.96`、`1/25s`、`ISO640`。
4. 页面状态由 `PhotoFrameController` 管理，UI 只负责展示和触发命令。

导出流程：

1. 用户选择边框样式。
2. 每张图片都维护独立参数，用户只会调整当前选中图片的样式、边框和设备名称。
3. 用户可保存当前选中图片的配置、加载已保存配置，或者把当前参数一键应用到全部照片。
4. 用户可选择固定导出目录；未设置时，桌面端默认回写到原图所在目录，Android 端保存到系统相册 `Pictures/imgFrame`。
5. 预览层和导出层都通过 `FrameLayoutMetrics` + `FrameOptions` 计算布局，避免预览与成品图使用两套比例。
6. `FrameRenderer` 在后台 isolate 中基于原图尺寸生成 PNG，主体照片不按固定宽度缩放；导出过程会显示当前照片序号和当前照片处理百分比，异常时通过超时保护返回错误信息。
7. 沉浸柔光样式先生成铺满画布的模糊背景，再叠加圆角主图、Leica 标识和底部参数。
8. 白底信息栏样式生成照片主体和底部信息栏，信息块会随 Leica 标识的左/中/右位置重新排布，并按实际宽度截断文本。
9. Windows 端直接写入目标目录；Android 端通过项目内原生 MethodChannel 调用 `MediaStore` 保存 PNG；Web 端触发浏览器下载。

## 工程结构

```text
assets/
  branding/
    logo.png
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
          export_progress.dart
          export_storage_io.dart
          export_storage_web.dart
          exif_metadata_reader.dart
          frame_export_service.dart
          frame_settings_storage.dart
          frame_renderer.dart
          leica_badge_png.dart
          photo_import_service.dart
        domain/
          frame_layout.dart
          frame_options.dart
          frame_style.dart
          leica_badge_path.dart
          photo_frame_settings.dart
          photo_asset.dart
        presentation/
          pages/
            photo_frame_page.dart
          widgets/
            empty_state.dart
            exif_panel.dart
            photo_gallery.dart
            leica_badge.dart
            photo_preview.dart
            style_selector.dart
windows/
  runner/
    resources/
      app_icon.ico
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
- Windows Release：已验证可构建，产物为 `dist/imgFrame-windows-x64.zip`。
- Android Release：已验证可构建，产物为 `dist/imgFrame-android-release.apk`。
- Web Release：已验证可构建，产物为 `dist/imgFrame-web.zip`。

主要设计取舍：

- 导出图使用 Dart `image` 包离屏合成，减少平台原生差异，便于 Android、Windows、Web 等端复用。
- 预览图使用 Flutter Widget 实时渲染，保证交互流畅；导出图由 `FrameRenderer` 基于原图像素重新生成 PNG，主体照片不降采样，PNG 使用无损快速编码以降低导出耗时。
- 预览和导出共用 `FrameLayoutMetrics` 与 `FrameOptions`：样式、边框比例、Logo 大小、字号、字段显隐和 Logo 位置都由同一份配置驱动。
- 每张照片都有独立的 `PhotoFrameSettings`；保存/加载配置会作用于当前照片，应用到全部会把当前照片的配置复制给所有图片。
- 移动端和桌面端使用同一套 Inspector 功能，只在布局上区分宽屏三栏和手机纵向滚动。平台不支持的固定导出目录选择会显示平台说明。
- Android 导出不依赖第三方保存插件，改由 `MainActivity` 内的原生 `MediaStore` 保存通道完成，降低系统文件选择器或插件回调导致的挂起风险。
- 根目录原始 `logo.png` 已移动到 `assets/branding/logo.png`，用于关于界面和 Flutter 资源；原始 `logo.ico` 已移动并替换 `windows/runner/resources/app_icon.ico`，用于 Windows 可执行文件图标。
- Android `mipmap-*dpi/ic_launcher.png` 和 Web `favicon.png`、`web/icons/*` 均由 `assets/branding/logo.png` 按目标尺寸生成。
- 状态管理暂用 `ChangeNotifier`，当前复杂度较低；当后续出现模板编辑、任务队列、配置持久化时，可以迁移到 Riverpod 或 Bloc。

## 技术报告

EXIF 字段兼容策略：

- EXIF 不同品牌字段名不完全一致，读取时会按候选字段顺序兜底。
- 参数格式化统一在 `ExifMetadataReader` 内完成，避免 UI 到处处理 `Ratio`、空值和品牌重复名。
- GPS 输出为 `纬度°N/S 经度°E/W`，当前仅展示，不做地图逆地理编码。
- 用户可以按字段隐藏相机、镜头、焦距、光圈、快门、ISO、时间和位置。字段显隐会同时影响预览和导出。

渲染策略：

- 导出画布不再使用固定宽度；白底信息栏样式保持原图宽度并向下追加信息栏，沉浸柔光样式在原图四周按比例追加边框区域。
- 主体照片使用原始像素直接合成，不做降采样；只有柔光背景、阴影和 Leica 标识会按目标区域重采样。
- 沉浸柔光样式使用背景 cover 裁剪、低分辨率快速 box blur、半透明遮罩和圆角主体；阴影模糊使用局部低分辨率图层，圆角只处理四角区域，减少大图导出耗时和内存占用。
- 白底信息栏样式使用随原图宽度等比计算的底栏高度，信息块会根据 Leica 标识左/中/右位置自动调整，便于信息对齐和批量输出风格统一。
- Leica 标识预览层使用 Simple Icons 的矢量路径绘制；导出层使用预生成 PNG 字节，避免导出时调用 `dart:ui Picture.toImage` 在部分平台上挂起。

风险与后续优化：

- `image` 内置位图字体主要覆盖 ASCII，导出图中的中文文本当前会回退或被裁剪；如要在导出图片中完整绘制中文，建议后续接入 TTF 字体渲染方案。
- 大批量超高像素照片在移动端可能有内存压力，后续可继续优化为流式读取和更细粒度的渲染进度。
- Leica 标识路径来自 Simple Icons，仅用于参考风格展示，不代表官方授权；商业发布前建议替换为用户可配置 Logo 或自有品牌标识。

## 导出保存策略

不同平台的保存路径和实现不同：

- Windows：未设置固定目录时导出到原图所在目录；设置固定目录后导出到所选目录。
- Android：导出到系统媒体库的 `Pictures/imgFrame`，在系统相册或文件管理器的图片目录中查看。
- Web：通过浏览器下载机制保存，文件进入浏览器默认下载目录或下载记录。

如果导出时长时间处于加载状态，优先确认是否安装了最新构建产物。当前实现已经对渲染和保存增加超时保护，异常时会通过页面底部提示返回错误信息，而不是无限转圈。

导出过程中页面底部会显示进度：单张导出显示 `1/1`，批量导出显示当前 `N/X`，并同步显示当前正在处理照片的百分比。进度条使用独立监听更新，不会反复重建照片预览区域。进度面板同时包含圆形进度、线性进度和当前处理阶段，窄屏设备会使用更紧凑的边距。

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
flutter build web --release
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

Android 导出照片会写入系统媒体库 `Pictures/imgFrame`。Android 10 及以上通过 `MediaStore` 写入，不需要用户手动选择保存文件；Android 9 及以下需要 `WRITE_EXTERNAL_STORAGE` 权限。

## 构建产物

Web Release 构建后，浏览器静态资源目录位于：

```text
build/web/
```

打包到分发目录后的 Web 压缩包位于：

```text
dist/imgFrame-web.zip
```

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

复制到分发目录后的 Windows 压缩包位于：

```text
dist/imgFrame-windows-x64.zip
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

最近一次本机打包结果：

```text
dist/imgFrame-android-release.apk  58,178,983 bytes  2026-05-24 18:12
dist/imgFrame-windows-x64.zip      13,772,193 bytes  2026-05-24 18:15
```

本仓库提供了便携工具链安装脚本，会把 JDK 和 Android SDK 下载到 `.tools/`，不写入仓库：

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\install_android_toolchain.ps1
```

该脚本需要能访问 Adoptium 和 Google Android Repository。
