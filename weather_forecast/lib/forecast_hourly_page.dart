import 'package:flutter/material.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/weather.dart';
import 'package:weather_forecast/extensions.dart';

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
                      condition: locationForecasts.first.forecast[index]);
                }),
          )
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
    final conditionImage = condition.image;
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
              Text(condition.getFormattedHour()),
              Text(condition.getFormattedDate())
            ],
          ),
          FutureBuilder(
              future: ImageHandler.decodeImageData(conditionImage,
                  width: 30, height: 30), // Decodes the image data.
              builder: (context, snapshot) {
                if (snapshot.data != null)
                  return RawImage(image: snapshot.data!);
                return Container();
              }),
          Text("${tempHigh.value} ${tempHigh.unit}"),
        ],
      ),
    );
  }
}
