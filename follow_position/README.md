## Overview

This example app demonstrates the following features:
- Display a map.
- Show how to set live datasource & `startFollowingPosition`.

## Build instructions

Step 1. Download the SDK

Step 2. Extract SDK to the predefined folder (plugins/gem_kit)

Step 3. Go to the repository root folder which contains the ```pubspec.yaml``` and run the terminal command ```flutter pub get``` to fetch the required dependencies.

Step 4. You can build the app either in your IDE of choice and execute the Flutter project for your target platform or via command line:

- Build for Android:
  - Build an Android APK by executing ```flutter build apk [--debug|--release]``` and use the command ```flutter run --use-application-binary build/app/outputs/flutter-apk/app-[debug|release].apk``` to run on an attached device.
- Build for iOS:
  - Run ```pod install``` in the [ios folder](./ios/).
  - Then go back to the repository root folder and type ```flutter build ios``` to build a Runner.app. Type ```flutter run``` to build and run on an attached device.
  - You can open the ```<path/to>/ios/Runner.xcworkspace``` project in Xcode and execute and debug from there.
- Build for Web:
  - Check available runner with ```flutter devices```. If Chrome is installed, the previous command outputs a Chrome device that opens the Chrome browser with your app running, and a Web Server that provides the URL serving the app.
  - To generate a release build, type ```flutter build web```. To serve your app from localhost in Chrome, type ```flutter run -d chrome```.
