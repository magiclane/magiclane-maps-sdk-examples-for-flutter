// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

// Retrieves the local time for the region corresponding to the given coordinates.
Future<DateTime> getLocalTime(Coordinates referenceCoords) async {
  final completer = Completer<TimezoneResult>();

  TimezoneService.getTimezoneInfoFromCoordinates(
    coords: referenceCoords,
    time: DateTime.now(),
    onCompleteCallback: (error, result) {
      if (error == GemError.success) completer.complete(result);
    },
  );

  final timezoneResult = await completer.future;

  return timezoneResult.localTime;
}

IconData getTransportIcon(PTRouteType type) {
  switch (type) {
    case PTRouteType.bus:
      return Icons.directions_bus;
    case PTRouteType.underground:
      return Icons.directions_subway;
    case PTRouteType.railway:
      return Icons.directions_railway;
    case PTRouteType.tram:
      return Icons.directions_bus_filled;
    case PTRouteType.waterTransport:
      return Icons.directions_boat;
    case PTRouteType.misc:
      return Icons.miscellaneous_services;
  }
}

// Computes how many minutes remain until the PTTrip’s scheduled departure.
String calculateTimeDifference(DateTime localCurrentTime, PTTrip ptTrip) {
  return ptTrip.departureTime != null
      ? '${ptTrip.departureTime!.difference(localCurrentTime).inMinutes} min'
      : '–';
}
