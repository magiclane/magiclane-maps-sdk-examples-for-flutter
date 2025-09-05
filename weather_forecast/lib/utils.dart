// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/weather.dart';

// Formatting the date for display in DD/MM/YYYY format
String getFormattedDate(Conditions condition) {
  final day =
      (condition.stamp.day < 10 ? "0" : "") + condition.stamp.day.toString();
  final month =
      (condition.stamp.month < 10 ? "0" : "") +
      condition.stamp.month.toString();
  return "$day/$month/${condition.stamp.year}";
}

// Formatting the temperature for display
String getFormattedTemperature(Conditions condition) {
  final tempHigh = condition.params
      .where((element) => element.type == "TemperatureHigh")
      .first;
  final tempLow = condition.params
      .where((element) => element.type == "TemperatureLow")
      .first;
  return '${tempHigh.value.toStringAsFixed(0)}${tempHigh.unit} / ${tempLow.value.toStringAsFixed(0)}${tempLow.unit}';
}

// Formatting the timestamp for display.
String getFormattedHour(Conditions condition) {
  return "${condition.stamp.hour.toString().padLeft(2, '0')}:${condition.stamp.minute.toString().padLeft(2, '0')}";
}

// Formatting parameter's seconds since the Unix epoch to DateTime for display
String getFormattedHourWithParam(Parameter time) {
  return "${DateTime.fromMillisecondsSinceEpoch((time.value * 1000).toInt()).hour.toString().padLeft(2, '0')} : ${DateTime.fromMillisecondsSinceEpoch((time.value * 1000).toInt()).minute.toString().padLeft(2, '0')}";
}

// Formatting the timestamp for display.
String getFormattedHouForecast(LocationForecast forecast) {
  return "${(forecast.updated.hour).toString().padLeft(2, '0')} : ${forecast.updated.minute.toString().padLeft(2, '0')}";
}
