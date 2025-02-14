// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/routing.dart';

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
