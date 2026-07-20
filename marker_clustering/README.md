## Overview

This example app demonstrates the following features:

- Render thousands of markers loaded from a bundled GeoJSON file
- Group markers into native count "pill" clusters at low zoom
- Show per-type coloured pins (green = info-only, red = bookable) once clusters break apart
- Tap a cluster to zoom in and split it, tap a pin to show an info sheet

The map uses **two overlapping SDK-drawn marker collections**. A marker that
carries its own per-marker render settings suppresses the SDK's cluster count
label, so the count and the coloured pins cannot come from a single collection:

- **Cluster layer** — one point-marker per campsite with collection-level
  settings only. The SDK groups the points into density "pill" bubbles and
  paints the **count** on them; loose points draw a transparent image.
- **Detail layer** — one coloured green/red pin per campsite via
  `markers.addList(...)` (the SDK's optimised bulk path). Its group images are
  transparent, so it shows nothing while clustered and only its pins once
  clusters split.

Both collections group at the same zoom level, so a pill never sits on top of a pin.

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