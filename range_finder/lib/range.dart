// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'package:gem_kit/routing.dart';

import 'dart:ui';

class Range {
  final Route route;
  final Color color;
  final RouteTransportMode transportMode;
  final String value;
  bool isEnabled;

  Range(
      {required this.route,
      required this.color,
      required this.transportMode,
      required this.value,
      required this.isEnabled});
}
