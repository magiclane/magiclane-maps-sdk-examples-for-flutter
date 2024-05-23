// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

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
    final totalDistance = timeDistance.unrestrictedDistanceM + timeDistance.restrictedDistanceM;
    final totalDuration = timeDistance.unrestrictedTimeS + timeDistance.restrictedTimeS;

    return '${convertDistance(totalDistance)} \n${convertDuration(totalDuration)}';
  }
}

// Define an extension for route instruction to calculate distance and duration
extension RouteInstructionExtension on RouteInstruction {
  String getFormattedDistanceUntilInstruction() {
    final rawDistance = traveledTimeDistance.restrictedDistanceM + traveledTimeDistance.unrestrictedDistanceM;
    return convertDistance(rawDistance);
  }
}
