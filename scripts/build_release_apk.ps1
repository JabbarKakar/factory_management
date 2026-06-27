# Builds a release APK for sideloading on factory devices.
# Output: build/app/outputs/flutter-apk/app-release.apk (and per-ABI splits if enabled)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Push-Location $PSScriptRoot\..

try {
    flutter clean
    flutter pub get
    flutter build apk --release

    Write-Host ""
    Write-Host "Release APK built successfully." -ForegroundColor Green
    Write-Host "Universal APK: build\app\outputs\flutter-apk\app-release.apk"
    Get-ChildItem "build\app\outputs\flutter-apk\*.apk" | ForEach-Object {
        Write-Host " - $($_.FullName) ($([math]::Round($_.Length / 1MB, 1)) MB)"
    }
}
finally {
    Pop-Location
}
