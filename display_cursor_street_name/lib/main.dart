// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'package:flutter/material.dart' hide Animation;

const projectApiToken = String.fromEnvironment('GEM_TOKEN');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        title: 'Display Current Street Name',
        debugShowCheckedModeBanner: false,
        home: MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late GemMapController _mapController;
  String _currentStreetName = "";

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
        title: const Text('Display Cursor Street Name',
            style: TextStyle(color: Colors.white)),
      ),
      body: Stack(alignment: AlignmentDirectional.bottomCenter, children: [
        GemMap(
          onMapCreated: _onMapCreated,
          appAuthorization: projectApiToken,
        ),
        if (_currentStreetName != "")
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 25.0),
            child: Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_currentStreetName),
                )),
          ),
      ]),
    );
  }

  // The callback for when map is ready to use.
  void _onMapCreated(GemMapController controller) async {
    // Save controller for further usage.
    _mapController = controller;

    _mapController.centerOnCoordinates(
        Coordinates(latitude: 45.472358, longitude: 9.184945));

    // Enable cursor to render on screen
    _mapController.preferences.enableCursor = true;
    _mapController.preferences.enableCursorRender = true;

    // Register touch callback to set cursor to tapped position
    _mapController.registerTouchCallback((point) {
      _mapController.setCursorScreenPosition(point);
      final streets = _mapController.cursorSelectionStreets();
      setState(() {
        _currentStreetName =
            streets.isEmpty ? "Unnamed street" : streets.first.name;
      });
    });
  }
}
