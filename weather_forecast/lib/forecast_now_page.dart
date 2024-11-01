import 'package:flutter/material.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/weather.dart';
import 'package:weather_forecast/extensions.dart';

class ForecastNowPage extends StatelessWidget {
  /// Holds the weather condition and forecast data.
  final LocationForecast condition;

  /// The name of the landmark or location for which the weather forecast is displayed.
  final String landmarkName;

  const ForecastNowPage(
      {super.key, required this.condition, required this.landmarkName});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 80,
              width: 80,
              child: FutureBuilder(
                  future: ImageHandler.decodeImageData(
                      condition.forecast.first.image,
                      width: 30,
                      height:
                          30), // Decodes the image data for the weather icon.
                  builder: (context, snapshot) {
                    if (snapshot.data != null)
                      return RawImage(image: snapshot.data!);
                    return Container();
                  }),
            ),
            Text(condition.forecast.first.description),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListView(
              shrinkWrap: true,
              children: [
                Column(
                  children: [
                    Text(
                      landmarkName,
                      style: TextStyle(fontSize: 20.0),
                    ),
                    Text("Updated at ${condition.getFormattedHour()}"),
                  ],
                ),
                for (final param in condition.forecast.first.params)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(param.name),
                        Row(
                          children: [
                            Text(param.type == "Sunrise" ||
                                    param.type == "Sunset"
                                ? param.getFormattedHour()
                                : param.value.toString()),
                            Text(param.unit),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
