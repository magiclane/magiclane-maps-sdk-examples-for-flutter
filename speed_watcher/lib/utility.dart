// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/routing.dart';

// Utility function to convert meters per second into kilometers per hour
double mpsToKmph(double metersPerSecond) {
  double kilometersPerHour = metersPerSecond * 3.6;
  kilometersPerHour = kilometersPerHour.roundToDouble();
  return kilometersPerHour;
}

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
    final totalDistance = getTimeDistance().unrestrictedDistanceM +
        getTimeDistance().restrictedDistanceM;
    final totalDuration =
        getTimeDistance().unrestrictedTimeS + getTimeDistance().restrictedTimeS;

    return '${convertDistance(totalDistance)} \n${convertDuration(totalDuration)}';
  }
}
