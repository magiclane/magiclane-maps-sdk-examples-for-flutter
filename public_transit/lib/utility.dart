// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'package:gem_kit/routing.dart';

// Utility function to convert the meters distance into a suitable format
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
  int hours = seconds ~/ 3600; // Number of whole hours
  int minutes = (seconds % 3600) ~/ 60; // Number of whole minutes

  String hoursText = (hours > 0) ? '$hours h ' : ''; // Hours text
  String minutesText = '$minutes min'; // Minutes text

  return hoursText + minutesText;
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
    if (publicTransitRoute == null)
      return ""; // If no route is available, return an empty string.

    // Get the first and last segments of the route.
    final firstSegment = publicTransitRoute.segments.first.toPTRouteSegment();
    final lastSegment = publicTransitRoute.segments.last.toPTRouteSegment();

    // Get departure and arrival times from the segments.
    final departureTime = firstSegment.departureTime;
    final arrivalTime = lastSegment.arrivalTime;

    // Calculate total walking distance (first and last segments are typically walking).
    final totalWalkingDistance = firstSegment.timeDistance.totalDistanceM +
        lastSegment.timeDistance.totalDistanceM;

    // Format departure and arrival times.
    final formattedDepartureTime =
        '${departureTime.hour}:${departureTime.minute.toString().padLeft(2, '0')}';
    final formattedArrivalTime =
        '${arrivalTime.hour}:${arrivalTime.minute.toString().padLeft(2, '0')}';

    // Build the label string with the route's details.
    return '${convertDuration(totalDuration)}\n' // Total duration
        '$formattedDepartureTime - $formattedArrivalTime\n' // Time range
        '${convertDistance(totalDistance)} ' // Total distance
        '(${convertDistance(totalWalkingDistance)} walking)\n' // Walking distance
        '${publicTransitRoute.publicTransportFare}'; // Fare
  }
}
