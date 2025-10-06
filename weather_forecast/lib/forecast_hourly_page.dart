// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:flutter/material.dart';
import 'package:magiclane_maps_flutter/weather.dart';
import 'package:weather_forecast/utils.dart';

class ForecastHourlyPage extends StatelessWidget {
  final List<LocationForecast> locationForecasts;

  const ForecastHourlyPage({super.key, required this.locationForecasts});

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
                return WeatherForecastHourlyItem(
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

class WeatherForecastHourlyItem extends StatelessWidget {
  /// The weather conditions for a specific hour.
  final Conditions condition;

  const WeatherForecastHourlyItem({super.key, required this.condition});

  @override
  Widget build(BuildContext context) {
    // Extracting the image and temperature information from the condition.
    final conditionImage = condition.img;
    final tempHigh = condition.params
        .where((element) => element.type == "Temperature")
        .first;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(getFormattedHour(condition)),
              Text(getFormattedDate(condition)),
            ],
          ),
          conditionImage.isValid
              ? Image.memory(conditionImage.getRenderableImageBytes()!)
              : SizedBox(),
          Text("${tempHigh.value} ${tempHigh.unit}"),
        ],
      ),
    );
  }
}
