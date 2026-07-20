// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.
//
// Converts between the standard 0–22 web-map zoom scale and Magic Lane zoom
// levels, so the clustering thresholds map onto familiar web-map zooms.

class MapZoomConverter {
  /// Converts a 0–22 web-map zoom to a Magic Lane zoom level.
  static int toMagicLaneZoom(double appZoom) {
    final clamped = appZoom.clamp(0.0, 22.0);
    return (clamped * 7.0 + 4.0).toInt();
  }

  /// Converts a Magic Lane zoom level back to a 0–22 web-map zoom.
  static double fromMagicLaneZoom(int magicLaneZoom) => (magicLaneZoom - 4) / 7.0;
}
