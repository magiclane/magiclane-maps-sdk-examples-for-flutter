// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:magiclane_maps_flutter/routing.dart';

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
  int hours = seconds ~/ 3600;
  int minutes = (seconds % 3600) ~/ 60;
  int remainingSeconds = seconds % 60;

  String hoursText = (hours > 0) ? '$hours h ' : '';
  String minutesText = (minutes > 0) ? '$minutes min ' : '';
  String secondsText = (hours == 0 && minutes == 0)
      ? '$remainingSeconds sec'
      : '';

  return (hoursText + minutesText + secondsText).trim();
}

String getMapLabel(Route route) {
  return '${convertDistance(route.getTimeDistance().totalDistanceM)} \n${convertDuration(route.getTimeDistance().totalTimeS)}';
}
