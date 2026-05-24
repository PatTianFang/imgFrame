param(
  [string]$Flutter = "D:\flutter\flutter\bin\flutter.bat"
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor `
  [Net.SecurityProtocolType]::Tls13
$repo = Split-Path -Parent $PSScriptRoot
$tools = Join-Path $repo ".tools"
$jdkDir = Join-Path $tools "jdk"
$androidSdk = Join-Path $tools "android-sdk"
$downloads = Join-Path $tools "downloads"

New-Item -ItemType Directory -Force -Path $downloads, $jdkDir, $androidSdk | Out-Null

$jdkZip = Join-Path $downloads "temurin-jdk.zip"
if (!(Test-Path $jdkZip)) {
  Invoke-WebRequest `
    -Uri "https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jdk/hotspot/normal/eclipse" `
    -OutFile $jdkZip
}

if (!(Get-ChildItem -Path $jdkDir -Directory -ErrorAction SilentlyContinue | Select-Object -First 1)) {
  Expand-Archive -Path $jdkZip -DestinationPath $jdkDir -Force
}

$javaHome = (Get-ChildItem -Path $jdkDir -Directory | Select-Object -First 1).FullName
$env:JAVA_HOME = $javaHome
$env:Path = "$javaHome\bin;$env:Path"

$repoXml = [xml](Invoke-WebRequest -Uri "https://dl.google.com/android/repository/repository2-1.xml").Content
$cmdlineArchive = $repoXml.SelectNodes("//remotePackage[@path='cmdline-tools;latest']/archives/archive") |
  Where-Object { $_.hostOs -eq "windows" } |
  Select-Object -First 1
$cmdlineUrl = "https://dl.google.com/android/repository/$($cmdlineArchive.complete.url)"
$cmdlineZip = Join-Path $downloads "android-commandline-tools.zip"

if (!(Test-Path $cmdlineZip)) {
  Invoke-WebRequest -Uri $cmdlineUrl -OutFile $cmdlineZip
}

$cmdlineRoot = Join-Path $androidSdk "cmdline-tools"
$cmdlineLatest = Join-Path $cmdlineRoot "latest"
if (!(Test-Path $cmdlineLatest)) {
  $tmp = Join-Path $downloads "cmdline-tools-expanded"
  if (Test-Path $tmp) {
    Remove-Item -LiteralPath $tmp -Recurse -Force
  }
  New-Item -ItemType Directory -Force -Path $tmp | Out-Null
  Expand-Archive -Path $cmdlineZip -DestinationPath $tmp -Force
  New-Item -ItemType Directory -Force -Path $cmdlineRoot | Out-Null
  Move-Item -LiteralPath (Join-Path $tmp "cmdline-tools") -Destination $cmdlineLatest
  Remove-Item -LiteralPath $tmp -Recurse -Force
}

$env:ANDROID_HOME = $androidSdk
$env:ANDROID_SDK_ROOT = $androidSdk
$sdkmanager = Join-Path $cmdlineLatest "bin\sdkmanager.bat"

"y" | & $sdkmanager --sdk_root=$androidSdk --licenses
& $sdkmanager --sdk_root=$androidSdk "platform-tools" "platforms;android-36" "build-tools;36.0.0"
& $Flutter config --android-sdk $androidSdk

Write-Host "JAVA_HOME=$javaHome"
Write-Host "ANDROID_HOME=$androidSdk"
