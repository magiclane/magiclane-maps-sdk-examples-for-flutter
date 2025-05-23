// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

//Copy the .gm file from assets directory to app documents directory
Future<void> copyLogToAppDocsDir(String logName) async {
  if (!kIsWeb) {
    final logsDirectory = await getDirectoryPath("Tracks");
    final gpxFile = File('$logsDirectory/$logName');
    final fileBytes = await rootBundle.load('assets/$logName');
    final buffer = fileBytes.buffer;
    await gpxFile.writeAsBytes(
      buffer.asUint8List(fileBytes.offsetInBytes, fileBytes.lengthInBytes),
    );
  }
}
