## Overview

This example app demonstrates the following features:
- Display a map.
- Calculate route.
- Display route.
- Start simulation.
- Show speed indicator panel.

## Build instructions

### 1. Android

- Generate an APK using the command: `flutter build apk` with optional `--debug` or `--release` flags
- Deploy to a connected device using: `flutter run --use-application-binary build/app/outputs/flutter-apk/app-[debug|release].apk`

### 2. iOS

- Clean the project workspace: `flutter clean`
- Fetch dependencies: `flutter pub get`
- Build the iOS application: `flutter build ios`
- Deploy to a connected device: `flutter run`

Alternatively, open the Xcode workspace located at `<project-path>/ios/Runner.xcworkspace` to build, execute and debug directly from Xcode.

### 3. Web

- Verify available target devices: `flutter devices`
  If Chrome is installed, this will display a Chrome device option (launches browser) and a Web Server option (provides localhost URL)
- Generate a production build: `flutter build web`
- Run in development mode: `flutter run -d chrome` (serves application on localhost in Chrome)