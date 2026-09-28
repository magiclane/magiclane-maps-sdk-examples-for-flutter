## Overview

This example app demonstrates the following features:
- Display a map.
- Show how to set live datasource & `startFollowingPosition`.
- Sensor data recording including NMEA chunks and device information.
- Export the log as CSV file.

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

This example does not work on the web: it relies on `dart:io` (`Platform`, `File`) to store and export the recorded log, and NMEA chunks are only available on Android.
