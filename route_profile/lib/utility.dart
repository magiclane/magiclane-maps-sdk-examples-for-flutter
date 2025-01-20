import 'dart:ui';

import 'package:gem_kit/routing.dart';

enum Steepness {
  descendExtreme,
  descendVeryHigh,
  descendHigh,
  descendLow,
  descendVeryLow,
  neutral,
  ascendVeryLow,
  ascendLow,
  ascendHigh,
  ascendVeryHigh,
  ascendExtreme,
}

// Utility function to convert the meters distance into a suitable format.
String convertDistance(double meters) {
  if (meters >= 1000) {
    double kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(1)} km';
  } else {
    return '${meters.toStringAsFixed(1)} m';
  }
}

// Get the color of the section based on its type
Color getColorBasedOnType(Enum type) {
  if (type is SurfaceType) return _getSurfaceTypeColor(type);
  if (type is RoadType) return _getRoadTypeColor(type);
  if (type is Steepness) return _getSteepnessColor(type);
  return const Color.fromARGB(255, 10, 10, 10);
}

// Get the color of the section based on surface type
Color _getSurfaceTypeColor(SurfaceType type) {
  switch (type) {
    case SurfaceType.asphalt:
      return const Color.fromARGB(255, 127, 137, 149);
    case SurfaceType.paved:
      return const Color.fromARGB(255, 212, 212, 212);
    case SurfaceType.unknown:
      return const Color.fromARGB(255, 10, 10, 10);
    case SurfaceType.unpaved:
      return const Color.fromARGB(255, 157, 133, 104);
    default:
      return const Color.fromARGB(255, 10, 10, 10);
  }
}

// Get the color of the section based on road type
Color _getRoadTypeColor(RoadType type) {
  switch (type) {
    case RoadType.motorways:
      return const Color.fromARGB(255, 242, 144, 99);
    case RoadType.stateRoad:
      return const Color.fromARGB(255, 242, 216, 99);
    case RoadType.cycleway:
      return const Color.fromARGB(255, 15, 175, 135);
    case RoadType.road:
      return const Color.fromARGB(255, 153, 163, 175);
    case RoadType.path:
      return const Color.fromARGB(255, 196, 200, 211);
    case RoadType.singleTrack:
      return const Color.fromARGB(255, 166, 133, 96);
    case RoadType.street:
      return const Color.fromARGB(255, 175, 185, 193);
    default:
      return const Color.fromARGB(255, 10, 10, 10);
  }
}

// Get the color of the section based on steepness
Color _getSteepnessColor(Steepness steepness) {
  switch (steepness) {
    case Steepness.descendExtreme:
      return const Color.fromARGB(255, 4, 120, 8);
    case Steepness.descendVeryHigh:
      return const Color.fromARGB(255, 38, 151, 41);
    case Steepness.descendHigh:
      return const Color.fromARGB(255, 73, 183, 76);
    case Steepness.descendLow:
      return const Color.fromARGB(255, 112, 216, 115);
    case Steepness.descendVeryLow:
      return const Color.fromARGB(255, 154, 250, 156);
    case Steepness.neutral:
      return const Color.fromARGB(255, 255, 197, 142);
    case Steepness.ascendVeryLow:
      return const Color.fromARGB(255, 240, 141, 141);
    case Steepness.ascendLow:
      return const Color.fromARGB(255, 220, 105, 105);
    case Steepness.ascendHigh:
      return const Color.fromARGB(255, 201, 73, 73);
    case Steepness.ascendVeryHigh:
      return const Color.fromARGB(255, 182, 42, 42);
    case Steepness.ascendExtreme:
      return const Color.fromARGB(255, 164, 16, 16);
    default:
      return const Color.fromARGB(255, 10, 10, 10);
  }
}

// Get the color of the section based on grade
Color getGradeColor(ClimbSection section) {
  switch (section.grade) {
    case Grade.gradeHC:
      return const Color.fromARGB(100, 255, 100, 40);
    case Grade.grade1:
      return const Color.fromARGB(100, 255, 140, 40);
    case Grade.grade2:
      return const Color.fromARGB(100, 255, 180, 40);
    case Grade.grade3:
      return const Color.fromARGB(100, 255, 220, 40);
    case Grade.grade4:
      return const Color.fromARGB(100, 255, 240, 40);
    default:
      return const Color.fromARGB(100, 255, 240, 40);
  }
}

// Define an extension for route for calculating the total distance of the route.
extension RouteExtension on Route {
  int totalDistance() {
    return getTimeDistance().unrestrictedDistanceM +
        getTimeDistance().restrictedDistanceM;
  }
}
