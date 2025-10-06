// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';

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
      debugShowCheckedModeBanner: false,
      title: 'Center Area',
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
  late GemMapController _mapController;

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
        title: const Text('Center Area', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: _onCenterCoordinatesButtonPressed,
            icon: const Icon(Icons.adjust, color: Colors.white),
          ),
        ],
      ),
      body: GemMap(
        key: ValueKey("GemMap"),
        onMapCreated: _onMapCreated,
        appAuthorization: projectApiToken,
      ),
    );
  }

  // The callback for when map is ready to use.
  void _onMapCreated(GemMapController controller) async {
    // Save controller for further usage.
    _mapController = controller;
  }

  void _onCenterCoordinatesButtonPressed() {
    // Predefined area for Queens, New York.
    final area = RectangleGeographicArea(
      topLeft: Coordinates(
        latitude: 40.73254497605159,
        longitude: -73.82536953324063,
      ),
      bottomRight: Coordinates(
        latitude: 40.723227048410024,
        longitude: -73.77693793474619,
      ),
    );

    // Create an animation (optional).
    final animation = GemAnimation(type: AnimationType.linear);

    // Use the map controller to center on coordinates.

    _mapController.centerOnArea(area, animation: animation);
  }
}
