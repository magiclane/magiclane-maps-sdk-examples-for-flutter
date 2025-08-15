// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/routing.dart';

String convertDistance(int meters) {
  if (meters >= 1000) {
    double kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(1)} km';
  } else {
    return '${meters.toString()} m';
  }
}

String convertDuration(int milliseconds) {
  int totalSeconds = (milliseconds / 1000).floor();
  int hours = totalSeconds ~/ 3600;
  int minutes = (totalSeconds % 3600) ~/ 60;
  int seconds = totalSeconds % 60;

  String hoursText = (hours > 0) ? '$hours h ' : '';
  String minutesText = (minutes > 0) ? '$minutes min ' : '';
  String secondsText = '$seconds sec';

  return hoursText + minutesText + secondsText;
}

// Define an extension for route for calculating the route label which will be displayed on map
extension RouteExtension on Route {
  String getMapLabel() {
    // Get total distance and total duration from time distance.
    final totalDistance = getTimeDistance().unrestrictedDistanceM +
        getTimeDistance().restrictedDistanceM;
    final totalDuration =
        getTimeDistance().unrestrictedTimeS + getTimeDistance().restrictedTimeS;

    // Convert the route to a public transit route (PTRoute).
    final publicTransitRoute = toPTRoute();
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
        '${publicTransitRoute.publicTransportFare}'; // Fare
  }
}
