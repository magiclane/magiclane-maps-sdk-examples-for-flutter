// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/routing.dart';
import 'package:gem_kit/navigation.dart';

import 'package:intl/intl.dart';

import 'dart:typed_data';
import 'dart:ui';

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

// Utility function to convert a raw image in byte data
Future<Uint8List?> imageToUint8List(Image? image) async {
  if (image == null) return null;
  final byteData = await image.toByteData(format: ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

// Define an extension for route for calculating the route label which will be displayed on map
extension RouteExtension on Route {
  String getMapLabel() {
    final totalDistance =
        getTimeDistance().unrestrictedDistanceM +
        getTimeDistance().restrictedDistanceM;
    final totalDuration =
        getTimeDistance().unrestrictedTimeS + getTimeDistance().restrictedTimeS;

    return '${convertDistance(totalDistance)} ${convertDuration(totalDuration)}';
  }
}

// Define an extension for navigation instruction to calculate distance and duration
extension NavigationInstructionExtension on NavigationInstruction {
  String getFormattedDistanceToNextTurn() {
    final totalDistanceToTurn =
        timeDistanceToNextTurn.unrestrictedDistanceM +
        timeDistanceToNextTurn.restrictedDistanceM;
    return convertDistance(totalDistanceToTurn);
  }

  String getFormattedDurationToNextTurn() {
    final totalDurationToTurn =
        timeDistanceToNextTurn.unrestrictedTimeS +
        timeDistanceToNextTurn.restrictedTimeS;
    return convertDuration(totalDurationToTurn);
  }

  String getFormattedRemainingDistance() {
    final remainingDistance =
        remainingTravelTimeDistance.unrestrictedDistanceM +
        remainingTravelTimeDistance.restrictedDistanceM;
    return convertDistance(remainingDistance);
  }

  String getFormattedRemainingDuration() {
    final remainingDuration =
        remainingTravelTimeDistance.unrestrictedTimeS +
        remainingTravelTimeDistance.restrictedTimeS;
    return convertDuration(remainingDuration);
  }

  String getFormattedETA() {
    final remainingDuration =
        remainingTravelTimeDistance.unrestrictedTimeS +
        remainingTravelTimeDistance.restrictedTimeS;
    return getCurrentTime(additionalSeconds: remainingDuration);
  }
}
