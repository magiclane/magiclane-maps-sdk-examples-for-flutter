import 'package:magiclane_maps_flutter/routing.dart' show Route;

String convertDistance(int meters) {
  if (meters >= 1000) {
    double kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(1)} km';
  } else {
    return '$meters m';
  }
}

String convertDuration(int seconds) {
  int hours = seconds ~/ 3600;
  int minutes = (seconds % 3600) ~/ 60;

  String hoursText = (hours > 0) ? '$hours h ' : '';
  String minutesText = '$minutes min';

  return hoursText + minutesText;
}

String getMapLabel(Route route) {
  return '${convertDistance(route.getTimeDistance().totalDistanceM)} \n${convertDuration(route.getTimeDistance().totalTimeS)}';
}
