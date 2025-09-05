// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/navigation.dart';
import 'package:gem_kit/routing.dart';

import 'package:intl/intl.dart';

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

// Utility function to add the given additional time to current time
String getCurrentTime({
  int additionalHours = 0,
  int additionalMinutes = 0,
  int additionalSeconds = 0,
}) {
  var now = DateTime.now();
  var updatedTime = now.add(
    Duration(
      hours: additionalHours,
      minutes: additionalMinutes,
      seconds: additionalSeconds,
    ),
  );
  var formatter = DateFormat('HH:mm');
  return formatter.format(updatedTime);
}

String getMapLabel(Route route) {
  return '${convertDistance(route.getTimeDistance().totalDistanceM)} \n${convertDuration(route.getTimeDistance().totalTimeS)}';
}

String getFormattedDistanceToNextTurn(NavigationInstruction navInstruction) {
  final totalDistanceToTurn =
      navInstruction.timeDistanceToNextTurn.unrestrictedDistanceM +
      navInstruction.timeDistanceToNextTurn.restrictedDistanceM;
  return convertDistance(totalDistanceToTurn);
}

String getFormattedDurationToNextTurn(NavigationInstruction navInstruction) {
  final totalDurationToTurn =
      navInstruction.timeDistanceToNextTurn.unrestrictedTimeS +
      navInstruction.timeDistanceToNextTurn.restrictedTimeS;
  return convertDuration(totalDurationToTurn);
}

String getFormattedRemainingDistance(NavigationInstruction navInstruction) {
  final remainingDistance =
      navInstruction.remainingTravelTimeDistance.unrestrictedDistanceM +
      navInstruction.remainingTravelTimeDistance.restrictedDistanceM;
  return convertDistance(remainingDistance);
}

String getFormattedRemainingDuration(NavigationInstruction navInstruction) {
  final remainingDuration =
      navInstruction.remainingTravelTimeDistance.unrestrictedTimeS +
      navInstruction.remainingTravelTimeDistance.restrictedTimeS;
  return convertDuration(remainingDuration);
}

String getFormattedETA(NavigationInstruction navInstruction) {
  final remainingDuration =
      navInstruction.remainingTravelTimeDistance.unrestrictedTimeS +
      navInstruction.remainingTravelTimeDistance.restrictedTimeS;
  return getCurrentTime(additionalSeconds: remainingDuration);
}
