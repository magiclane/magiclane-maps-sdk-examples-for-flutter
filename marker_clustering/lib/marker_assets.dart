// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.
//
// Marker artwork:
//   • pin_bookable.png      — bookable campsite  (red  #DD3137, tent glyph)
//   • pin_non_bookable.png  — not bookable       (green #007228, tent glyph)
//
// The cluster capsule (#0C4B22) is drawn in code so it can widen for 3- and
// 4-digit counts instead of being a fixed-width asset. The count itself is drawn
// over the capsule by the SDK's group-labeling engine, so we only render the
// background here.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:magiclane_maps_flutter/core.dart';

class MarkerAssets {
  MarkerAssets._(this.bookablePin, this.notBookablePin, this.lowPill,
      this.mediumPill, this.highPill, this.transparent);

  /// Red pin, for bookable campsites.
  final GemImage bookablePin;

  /// Green pin, for info-only campsites.
  final GemImage notBookablePin;

  /// Cluster capsules, sized for 2 / 3 / 4 digit counts.
  final GemImage lowPill;
  final GemImage mediumPill;
  final GemImage highPill;

  /// A fully transparent image, used where a layer should draw nothing (the
  /// cluster layer's loose singles, and the detail layer's grouped state).
  final GemImage transparent;

  static Future<MarkerAssets> load() async {
    final bookable = await _pngImage('assets/pin_bookable.png');
    final notBookable = await _pngImage('assets/pin_non_bookable.png');
    final low = _pill(await _makePill(digits: 2));
    final medium = _pill(await _makePill(digits: 3));
    final high = _pill(await _makePill(digits: 4));
    final transparent = _pill(await _makeTransparent());
    return MarkerAssets._(
        bookable, notBookable, low, medium, high, transparent);
  }

  GemImage pinFor({required bool bookable}) =>
      bookable ? bookablePin : notBookablePin;

  static Future<GemImage> _pngImage(String asset) async {
    final data = await rootBundle.load(asset);
    return GemImage(
      image: data.buffer.asUint8List(),
      format: ImageFileFormat.png,
    );
  }

  static GemImage _pill(Uint8List bytes) =>
      GemImage(image: bytes, format: ImageFileFormat.png);

  /// Cluster capsule background — a flat #0C4B22 capsule with a white 40%
  /// border. The visible capsule is only as wide as the digit count needs and
  /// centred in the (power-of-two) bitmap; the leftover side space stays
  /// transparent. The SDK centres the count label on the image, landing it
  /// dead-centre of the visible capsule.
  static Future<Uint8List> _makePill({required int digits}) async {
    const height = 64.0; // power-of-two
    final width = digits >= 3 ? 128.0 : 64.0; // 128 holds 3–4 digits
    final capsuleWidth = switch (digits) {
      >= 4 => 91.0, // snug 4-digit
      3 => 76.0, // snug 3-digit
      _ => 64.0, // 1–2 digit circle
    };
    final margin = (width - capsuleWidth) / 2.0;
    const stroke = height / 24.0;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final rect = ui.Rect.fromLTRB(
        margin + stroke, stroke, width - margin - stroke, height - stroke);
    final radius = ui.Radius.circular(rect.height / 2.0);
    final rrect = ui.RRect.fromRectAndRadius(rect, radius);

    // Dark-green body (#0C4B22) with a white 40% border — the SDK draws the
    // white count on top (labelGroupTextColor).
    final fill = ui.Paint()
      ..isAntiAlias = true
      ..style = ui.PaintingStyle.fill
      ..color = const ui.Color(0xFF0C4B22);
    canvas.drawRRect(rrect, fill);

    final border = ui.Paint()
      ..isAntiAlias = true
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const ui.Color(0x66FFFFFF); // white @ 40%
    canvas.drawRRect(rrect, border);

    final image =
        await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  /// A 64×64 fully transparent PNG (power-of-two so it rasterises cleanly).
  static Future<Uint8List> _makeTransparent() async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder); // draw nothing
    final image = await recorder.endRecording().toImage(64, 64);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}
