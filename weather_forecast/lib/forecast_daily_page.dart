// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:flutter/material.dart';
import 'package:gem_kit/weather.dart';
import 'package:weather_forecast/extensions.dart';

class ForecastDailyPage extends StatelessWidget {
  final List<LocationForecast> locationForecasts;

  const ForecastDailyPage({super.key, required this.locationForecasts});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: locationForecasts.first.forecast.length,
              itemBuilder: (context, index) {
                return WeatherForecastDailyItem(
                  condition: locationForecasts.first.forecast[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherForecastDailyItem extends StatelessWidget {
  /// The weather conditions for a specific day.
  final Conditions condition;

  const WeatherForecastDailyItem({super.key, required this.condition});

  @override
  Widget build(BuildContext context) {
    final conditionImage = condition.img;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_getWeekdayString(condition.stamp.weekday)),
              Text(condition.getFormattedDate()),
            ],
          ),
          conditionImage.isValid
              ? Image.memory(conditionImage.getRenderableImageBytes()!)
              : SizedBox(),
          Row(children: [Text(condition.getFormattedTemperature())]),
        ],
      ),
    );
  }

  // Converts a weekday index into a string representation.
  String _getWeekdayString(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }
}
