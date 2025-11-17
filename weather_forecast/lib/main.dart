// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:flutter/material.dart';

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';
import 'package:weather_forecast/weather_forecast_page.dart';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather Forecast',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void dispose() {
    GemKit.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[900],
        title: const Text(
          'Weather Forecast',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => _onWeatherForecastTap(context),
            icon: Icon(Icons.sunny, color: Colors.white),
          ),
        ],
      ),
      body: GemMap(key: ValueKey("GemMap"), appAuthorization: projectApiToken),
    );
  }

  void _onWeatherForecastTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<dynamic>(builder: (context) => WeatherForecastPage()),
    );
  }
}
