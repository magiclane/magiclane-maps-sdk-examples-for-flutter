// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/routing.dart';

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

String convertDistance(int meters) {
  if (meters >= 1000) {
    double kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(1)} km';
  } else {
    return '${meters.toString()} m';
  }
}

String convertDuration(int seconds) {
  int hours = seconds ~/ 3600; // Number of whole hours
  int minutes = (seconds % 3600) ~/ 60; // Number of whole minutes

  String hoursText = (hours > 0) ? '$hours h ' : ''; // Hours text
  String minutesText = '$minutes min'; // Minutes text

  return hoursText + minutesText;
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
    final totalDistance = getTimeDistance().unrestrictedDistanceM +
        getTimeDistance().restrictedDistanceM;
    final totalDuration =
        getTimeDistance().unrestrictedTimeS + getTimeDistance().restrictedTimeS;

    return '${convertDistance(totalDistance)} \n${convertDuration(totalDuration)}';
  }
}

// Define an extension for route instruction to calculate distance and duration
extension RouteInstructionExtension on RouteInstruction {
  String getFormattedDistanceUntilInstruction() {
    final rawDistance = traveledTimeDistance.restrictedDistanceM +
        traveledTimeDistance.unrestrictedDistanceM;
    return convertDistance(rawDistance);
  }
}
