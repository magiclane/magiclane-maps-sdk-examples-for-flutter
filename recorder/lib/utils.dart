// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

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

// Utility function to convert the milliseconds duration into a suitable format
String convertDurationMillis(int milliseconds) {
  if (milliseconds < 1000) return '$milliseconds ms';

  int totalSeconds = milliseconds ~/ 1000;
  int hours = totalSeconds ~/ 3600;
  int minutes = (totalSeconds % 3600) ~/ 60;
  int remainingSeconds = totalSeconds % 60;

  String hoursText = (hours > 0) ? '$hours h ' : '';
  String minutesText = (minutes > 0) ? '$minutes min ' : '';
  String secondsText = '$remainingSeconds sec';

  return (hoursText + minutesText + secondsText).trim();
}
