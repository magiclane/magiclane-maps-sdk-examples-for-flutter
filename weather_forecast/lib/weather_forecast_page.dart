// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/weather.dart';
import 'package:weather_forecast/forecast_daily_page.dart';
import 'package:weather_forecast/forecast_hourly_page.dart';
import 'package:weather_forecast/forecast_now_page.dart';

// Enum to represent the different weather forecast tabs
enum WeatherTab { now, hourly, daily }

class WeatherForecastPage extends StatefulWidget {
  const WeatherForecastPage({super.key});

  @override
  State<WeatherForecastPage> createState() => _WeatherForecastPageState();
}

class _WeatherForecastPageState extends State<WeatherForecastPage> {
  // Variable to track the selected weather tab, defaulting to 'now'
  WeatherTab _weatherTab = WeatherTab.now;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        foregroundColor: Colors.white,
        title: const Text(
          "Weather Forecast",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            // Tab buttons for 'Now', 'Hourly', and 'Daily' forecasts
            SizedBox(
              height: 40.0,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      child: Center(child: Text("Now")),
                      onTap: () => setState(() {
                        _weatherTab = WeatherTab.now;
                      }),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      child: Center(child: Text("Hourly")),
                      onTap: () => setState(() {
                        _weatherTab = WeatherTab.hourly;
                      }),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      child: Center(child: Text("Daily")),
                      onTap: () => setState(() {
                        _weatherTab = WeatherTab.daily;
                      }),
                    ),
                  ),
                ],
              ),
            ),

            // Display the selected forecast page
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_weatherTab == WeatherTab.now) {
                    return FutureBuilder(
                      future: _getCurrentForecast(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData) {
                          return Center(
                            child: Text("Error loading current forecast."),
                          );
                        }

                        return ForecastNowPage(
                          condition: snapshot.data!,
                          landmarkName: "Paris",
                        );
                      },
                    );
                  } else if (_weatherTab == WeatherTab.hourly) {
                    return FutureBuilder(
                      future: _getHourlyForecast(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData) {
                          return Center(
                            child: Text("Error loading hourly forecast."),
                          );
                        }

                        return ForecastHourlyPage(
                          locationForecasts: snapshot.data!,
                        );
                      },
                    );
                  } else if (_weatherTab == WeatherTab.daily) {
                    return FutureBuilder(
                      future: _getDailyForecast(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData) {
                          return Center(
                            child: Text("Error loading daily forecast."),
                          );
                        }

                        return ForecastDailyPage(
                          locationForecasts: snapshot.data!,
                        );
                      },
                    );
                  }
                  return Container();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<LocationForecast> _getCurrentForecast() async {
    final locationCoordinates = Coordinates(
      latitude: 48.864716,
      longitude: 2.349014,
    );
    final weatherCurrentCompleter = Completer<List<LocationForecast>>();

    WeatherService.getCurrent(
      coords: [locationCoordinates],
      onCompleteCallback: (err, result) async {
        weatherCurrentCompleter.complete(result);
      },
    );

    final currentForecast = await weatherCurrentCompleter.future;

    return currentForecast.first;
  }

  Future<List<LocationForecast>> _getHourlyForecast() async {
    final locationCoordinates = Coordinates(
      latitude: 48.864716,
      longitude: 2.349014,
    );
    final weatherHourlyCompleter = Completer<List<LocationForecast>>();

    WeatherService.getHourlyForecast(
      hours: 24,
      coords: [locationCoordinates],
      onCompleteCallback: (err, result) async {
        weatherHourlyCompleter.complete(result);
      },
    );

    final currentForecast = await weatherHourlyCompleter.future;

    return currentForecast;
  }

  Future<List<LocationForecast>> _getDailyForecast() async {
    final locationCoordinates = Coordinates(
      latitude: 48.864716,
      longitude: 2.349014,
    );
    final weatherDailyCompleter = Completer<List<LocationForecast>>();

    WeatherService.getDailyForecast(
      days: 10,
      coords: [locationCoordinates],
      onCompleteCallback: (err, result) async {
        weatherDailyCompleter.complete(result);
      },
    );

    final currentForecast = await weatherDailyCompleter.future;

    return currentForecast;
  }
}
