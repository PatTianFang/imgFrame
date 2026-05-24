param(
  [string]$Flutter = "D:\flutter\flutter\bin\flutter.bat"
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

& $Flutter pub get
& $Flutter analyze
& $Flutter test

& $Flutter create . --platforms=web,windows
& $Flutter build web --release
& $Flutter build windows --release

Write-Host "Web: $repo\build\web"
Write-Host "Windows: $repo\build\windows\x64\runner\Release"
