// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:gem_kit/core.dart';
import 'package:image/image.dart' as image;

abstract class ImageGenerator {
  static Future<Uint8List> createReferenceImage({
    required Size size,
    required ImageFileFormat format,
    Color bgColor = const Color.fromARGB(255, 0, 0, 255),
    Color fgColor = const Color.fromARGB(255, 255, 255, 0),
  }) async {
    final w = size.width.toInt();
    final h = size.height.toInt();

    final backgroundColor = image.ColorRgba8(
      (bgColor.r * 255).toInt(),
      (bgColor.g * 255).toInt(),
      (bgColor.b * 255).toInt(),
      (bgColor.a * 255).toInt(),
    );
    final foregroundColor = image.ColorRgba8(
      (fgColor.r * 255).toInt(),
      (fgColor.g * 255).toInt(),
      (fgColor.b * 255).toInt(),
      (fgColor.a * 255).toInt(),
    );

    var img = image.Image(width: w, height: h);
    img = image.fill(img, color: backgroundColor);
    img = image.drawLine(
      img,
      x1: 0,
      y1: 0,
      x2: w - 1,
      y2: h - 1,
      color: foregroundColor,
      antialias: true,
      thickness: 2,
    );
    img = image.drawLine(
      img,
      x1: w - 1,
      y1: 0,
      x2: 0,
      y2: h - 1,
      color: foregroundColor,
      antialias: true,
      thickness: 2,
    );

    switch (format) {
      case ImageFileFormat.png:
        return image.encodePng(img);
      case ImageFileFormat.jpeg:
        return image.encodeJpg(img);
      case ImageFileFormat.bmp:
        return image.encodeBmp(img);
      default:
        throw Exception('Format not supported yet');
    }
  }

  static Future<Uint8List> createTransparentReferenceImage({
    required Size size,
  }) async {
    final w = size.width.toInt();
    final h = size.height.toInt();

    var img = image.Image(width: w, height: h);
    img = image.fill(img, color: image.ColorRgba8(0, 0, 0, 0));
    img = image.drawCircle(
      img,
      x: w ~/ 2,
      y: h ~/ 2,
      radius: min(w ~/ 2, h ~/ 2),
      color: image.ColorRgb8(255, 0, 0),
      antialias: true,
    );
    return image.encodePng(img);
  }
}
