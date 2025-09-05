// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:device_info_plus/device_info_plus.dart';
import 'package:gem_kit/sense.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;

import 'dart:io';

Future<String> getDirectoryPath(String dirName) async {
  final docDirectory = Platform.isAndroid
      ? await path_provider.getExternalStorageDirectory()
      : await path_provider.getApplicationDocumentsDirectory();

  String absPath = docDirectory!.path;

  final expectedPath = path.joinAll([absPath, "Data", dirName]);
  return expectedPath;
}

// Utility function to convert the seconds duration into a suitable format
String convertDuration(int seconds) {
  int hours = seconds ~/ 3600;
  int minutes = (seconds % 3600) ~/ 60;
  int remainingSeconds = seconds % 60;

  String hoursText = (hours > 0) ? '$hours h ' : '';
  String minutesText = (minutes > 0) ? '$minutes min ' : '';
  String secondsText = (hours == 0 && minutes == 0)
      ? '$remainingSeconds sec'
      : '';

  return (hoursText + minutesText + secondsText).trim();
}

String getCSVFilePath(String logsDir, String fileName) {
  return path.joinAll([logsDir, "$fileName.csv"]);
}

Future<Map<HardwareSpecification, String>> getDeviceInfo() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    return {
      HardwareSpecification.manufacturer: androidInfo.manufacturer,
      HardwareSpecification.osVersion: androidInfo.version.release,
      HardwareSpecification.totalRAM: androidInfo.physicalRamSize.toString(),
      HardwareSpecification.freeRAM: androidInfo.availableRamSize.toString(),
      HardwareSpecification.supportedABIs: androidInfo.supportedAbis.toString(),
    };
  }

  if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;

    return {
      HardwareSpecification.manufacturer: "Apple",
      HardwareSpecification.osVersion: iosInfo.systemVersion,
      HardwareSpecification.deviceModel: iosInfo.utsname.machine,
    };
  }

  return {};
}
