// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'dart:io';
import 'package:flutter/services.dart' show Uint8List, rootBundle;

extension FileExtension on File {
  String get name {
    final fileName = nameWithExtension;
    return fileName.split('.').first;
  }

  String get nameWithExtension => path.split('/').last;
}

Future<Uint8List> assetToUint8List(String assetPath) async {
  final byteData = await rootBundle.load(assetPath);
  return byteData.buffer.asUint8List();
}
