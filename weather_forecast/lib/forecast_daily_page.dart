import 'package:flutter/material.dart';
import 'package:gem_kit/core.dart';
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
                    condition: locationForecasts.first.forecast[index]);
              },
            ),
          )
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
          FutureBuilder(
              future: ImageHandler.decodeImageData(condition.image,
                  width: 30, height: 30), // Decodes the image data.
              builder: (context, snapshot) {
                if (snapshot.data != null)
                  return RawImage(image: snapshot.data!);
                return Container();
              }),
          Row(
            children: [
              Text(condition.getFormattedTemperature()),
            ],
          ),
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
      'Sunday'
    ];
    return weekdays[weekday - 1];
  }
}
