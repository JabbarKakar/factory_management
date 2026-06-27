# MFMS — Marble Factory Management System

Flutter app for marble factory operations: job work, sales, inventory, labour, delivery, reports, and exports.

## Release APK (factory devices)

From the project root:

```powershell
.\scripts\build_release_apk.ps1
```

Or manually:

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

> Release builds currently use the debug signing key so you can install immediately. Replace `signingConfig` in `android/app/build.gradle.kts` before Play Store upload.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
