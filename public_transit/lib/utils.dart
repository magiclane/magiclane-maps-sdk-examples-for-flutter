// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:magiclane_maps_flutter/routing.dart';

String convertDistance(int meters) {
  if (meters >= 1000) {
    double kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(1)} km';
  } else {
    return '${meters.toString()} m';
  }
}

// Utility function to convert the seconds duration into a suitable format
String convertDuration(int seconds) {
  int hours = seconds ~/ 3600;
  int minutes = (seconds % 3600) ~/ 60;
  int remainingSeconds = seconds % 60;

  String hoursText = (hours > 0) ? '$hours h ' : '';
  String minutesText = (minutes > 0) ? '$minutes min ' : '';
  String secondsText =
      (hours == 0 && minutes == 0) ? '$remainingSeconds sec' : '';

  return (hoursText + minutesText + secondsText).trim();
}

String getMapLabel(Route route) {
  // Get total distance and total duration from time distance.
  final totalDistance = route.getTimeDistance().unrestrictedDistanceM +
      route.getTimeDistance().restrictedDistanceM;
  final totalDuration = route.getTimeDistance().unrestrictedTimeS +
      route.getTimeDistance().restrictedTimeS;

  // Convert the route to a public transit route (PTRoute).
  final publicTransitRoute = route.toPTRoute();
  if (publicTransitRoute == null) {
    return "";
  }

  // Get the first and last segments of the route.
  final firstSegment = publicTransitRoute.segments.first.toPTRouteSegment();
  final lastSegment = publicTransitRoute.segments.last.toPTRouteSegment();

  if (firstSegment == null || lastSegment == null) {
    return "";
  }

  // Get departure and arrival times from the segments.
  final departureTime = firstSegment.departureTime;
  final arrivalTime = lastSegment.arrivalTime;

  // Calculate total walking distance (first and last segments are typically walking).
  final totalWalkingDistance = firstSegment.timeDistance.totalDistanceM +
      lastSegment.timeDistance.totalDistanceM;

  String formattedDepartureTime = "";
  String formattedArrivalTime = "";

  if (departureTime != null && arrivalTime != null) {
    // Format departure and arrival times.
    formattedDepartureTime =
        '${departureTime.hour}:${departureTime.minute.toString().padLeft(2, '0')}';
    formattedArrivalTime =
        '${arrivalTime.hour}:${arrivalTime.minute.toString().padLeft(2, '0')}';
  }

  // Build the label string with the route's details.
  return '${convertDuration(totalDuration)}\n' // Total duration
      '$formattedDepartureTime - $formattedArrivalTime\n' // Time range
      '${convertDistance(totalDistance)} ' // Total distance
      '(${convertDistance(totalWalkingDistance)} walking)\n' // Walking distance
      '${publicTransitRoute.publicTransportFare ?? ""}'; // Fare
}
