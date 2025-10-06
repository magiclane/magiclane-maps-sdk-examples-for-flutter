// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:magiclane_maps_flutter/routing.dart';

import 'dart:ui';

class Range {
  final Route route;
  final Color color;
  final RouteTransportMode transportMode;
  final String value;
  bool isEnabled;

  Range({
    required this.route,
    required this.color,
    required this.transportMode,
    required this.value,
    required this.isEnabled,
  });
}
