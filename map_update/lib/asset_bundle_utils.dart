// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'dart:io';

import 'package:flutter/services.dart';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

extension AssetBundleExtension on AssetBundle {
  Future<void> loadOldMaps() async {
    const cmap = 'AndorraOSM_2021Q1.cmap';
    const worldMap = 'WM_7_406.map';

    final dirPath = await _getDirPath();
    final resFilePath = path.joinAll([dirPath.path, "Data", "Res"]);
    final mapsFilePath = path.joinAll([dirPath.path, "Data", "Maps"]);

    await _deleteAssets(resFilePath, RegExp(r'WM_\d_\d+\.map'));
    await _deleteAssets(mapsFilePath, RegExp(r'.+\.cmap'));

    await _loadAsset(cmap, mapsFilePath);
    await _loadAsset(worldMap, resFilePath);
  }

  Future<bool> _loadAsset(
    String assetName,
    String destinationDirectoryPath,
  ) async {
    final destinationFilePath = path.join(destinationDirectoryPath, assetName);

    File file = File(destinationFilePath);
    if (await file.exists()) {
      return false;
    }
    await file.create();

    final asset = await load('assets/$assetName');
    final buffer = asset.buffer;
    await file.writeAsBytes(
      buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
      flush: true,
    );
    print("Wrote file ${file.path}");
    return true;
  }

  Future<Directory> _getDirPath() async {
    if (Platform.isAndroid) {
      return (await getExternalStorageDirectory())!;
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      throw Exception('Platform not supported');
    }
  }

  Future<void> _deleteAssets(String directoryPath, RegExp pattern) async {
    final directory = Directory(directoryPath);

    if (!directory.existsSync()) {
      print(
        '\x1B[31mWARNING: Directory $directoryPath not found. Test might fail.\x1B[0m',
      );
    }

    for (final file in directory.listSync()) {
      final filename = path.basename(file.path);
      if (pattern.hasMatch(filename)) {
        try {
          print('INFO DELETE ASSETS: deleting file ${file.path}');
          file.deleteSync();
        } catch (e) {
          print(
            '\x1B[31mWARNING: Deleting file ${file.path} failed. Test might fail. Reason:\n${e.toString()}\x1B[0m',
          );
        }
      }
    }
  }
}
