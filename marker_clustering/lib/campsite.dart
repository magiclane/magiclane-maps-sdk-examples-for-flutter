// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.
//
// One value per campsite plus a streaming-friendly parser for the bundled
// campsites.geojson. Only the fields the map needs are decoded.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// One campsite. The green/red split is driven by [isBookable]
/// (green = bookable, red = not).
@immutable
class Campsite {
  const Campsite({
    required this.id,
    required this.name,
    required this.country,
    required this.reviewScore,
    required this.stars,
    required this.isBookable,
    required this.latitude,
    required this.longitude,
  });

  final int id; // campsiteId
  final String name;
  final String? country;
  final double? reviewScore;
  final int? stars;
  final bool isBookable;
  final double latitude;
  final double longitude;

  /// Short detail line shown under the name in the info sheet.
  String get subtitle {
    final parts = <String>[];
    if (stars != null && stars! > 0) parts.add('★' * stars!);
    if (reviewScore != null && reviewScore! > 0) {
      parts.add(reviewScore!.toStringAsFixed(1));
    }
    if (country != null && country!.isNotEmpty) parts.add(country!);
    parts.add(isBookable ? 'RV park' : 'Campground');
    return parts.join(' · ');
  }

  /// Marker name carried into the SDK. Encoded as JSON so a tapped marker can
  /// recover id / name / bookable straight from its name string — the only
  /// per-marker metadata channel the SDK exposes.
  String get markerName => jsonEncode({
        'id': id,
        'name': name,
        'bookable': isBookable,
        'address': subtitle,
      });

  /// Recovers the metadata from a tapped marker's (JSON) name. Falls back to the
  /// raw string when the payload isn't valid JSON.
  static Map<String, dynamic> decodeMarkerName(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {'name': raw};
  }
}

/// Loads and parses the bundled GeoJSON. The decode + flatten happens on a
/// background isolate ([compute]) so the multi-MB file never janks the UI thread.
class CampsiteLoader {
  static Future<List<Campsite>> loadFromAssets(
      [String asset = 'assets/campsites.geojson']) async {
    final raw = await rootBundle.loadString(asset);
    return compute(_parse, raw);
  }

  static List<Campsite> _parse(String raw) {
    final root = jsonDecode(raw) as Map<String, dynamic>;
    final features = (root['features'] as List?) ?? const [];
    final result = <Campsite>[];
    for (final feature in features) {
      final f = feature as Map<String, dynamic>;
      final geometry = f['geometry'] as Map<String, dynamic>?;
      final coords = geometry?['coordinates'] as List?;
      final props = f['properties'] as Map<String, dynamic>?;
      if (coords == null || coords.length < 2 || props == null) continue;

      final id = _asInt(props['campsiteId']);
      final lon = _asDouble(coords[0]);
      final lat = _asDouble(coords[1]);
      if (id == null || lat == null || lon == null) continue;

      result.add(Campsite(
        id: id,
        name: (props['name'] as String?) ?? '',
        country: props['country'] as String?,
        reviewScore: _asDouble(props['reviewScore']),
        stars: _asInt(props['stars']),
        isBookable: props['bookable'] == true,
        latitude: lat,
        longitude: lon,
      ));
    }
    return result;
  }

  static int? _asInt(Object? v) =>
      v is int ? v : (v is num ? v.toInt() : (v is String ? int.tryParse(v) : null));

  static double? _asDouble(Object? v) =>
      v is double ? v : (v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null));
}
