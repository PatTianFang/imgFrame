# 构建说明

## Windows

```powershell
flutter pub get
flutter build windows --release
```

Windows 插件构建需要符号链接权限。如果出现以下提示：

```text
Building with plugins requires symlink support.
Please enable Developer Mode in your system settings.
```

需要开启 Windows 开发者模式，或使用管理员 PowerShell 构建。可用以下命令打开设置页：

```powershell
start ms-settings:developers
```

产物目录：

```text
build/windows/x64/runner/Release/
```

分发时需要保留整个 `Release` 目录，而不是只复制 `img_frame.exe`。

也可以直接分发仓库内打好的压缩包：

```text
dist/imgFrame-windows-x64.zip
```

## Web

```powershell
flutter pub get
flutter build web --release
```

产物目录：

```text
build/web
```

可直接部署到静态站点服务，或者使用仓库内打好的压缩包：

```text
dist/imgFrame-web.zip
```

## Android

先安装 Android Studio 或 Android Command-line Tools，并确保 Flutter 能找到 Android SDK：

```powershell
flutter doctor -v
flutter config --android-sdk <Android SDK 路径>
flutter doctor --android-licenses
flutter build apk --release
```

APK 产物：

```text
build/app/outputs/flutter-apk/app-release.apk
```

如果要上架应用商店，应改用签名配置和 App Bundle：

```powershell
flutter build appbundle --release
```

仓库内也提供便携安装脚本：

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\install_android_toolchain.ps1
```

脚本会下载 JDK、Android command-line tools、platform-tools、Android platform 和 build-tools 到 `.tools/`。如果网络无法访问 `dl.google.com`，需要手动安装 Android Studio 或配置可访问的网络环境。
