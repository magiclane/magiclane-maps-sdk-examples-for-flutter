// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'package:flutter/services.dart' show rootBundle;

Future<void> main() async {
  const projectApiToken = String.fromEnvironment('GEM_TOKEN');

  await GemKit.initialize(appAuthorization: projectApiToken);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Marker Sketches',
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

  // Predefined coordinates for London, England.
  final _coordinates1 = Coordinates(latitude: 51.511704, longitude: -0.0535973);
  final _coordinates2 = Coordinates(latitude: 51.511174, longitude: -0.0535973);

  bool _isMarkerShown = false;

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
        title: const Text('Marker Sketches',
            style: TextStyle(color: Colors.white)),
        actions: [
          if (_isMarkerShown == false)
            IconButton(
              onPressed: () => _showMarkers(),
              icon: const Icon(
                Icons.draw,
                color: Colors.white,
              ),
            ),
          if (_isMarkerShown == true)
            IconButton(
              onPressed: () => _clearMarkers(),
              icon: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
        ],
      ),
      body: GemMap(
        onMapCreated: _onMapCreated,
      ),
    );
  }

  // The callback for when map is ready to use.
  void _onMapCreated(GemMapController controller) {
    // Save controller for further usage.
    _mapController = controller;
  }

  Future<void> _showMarkers() async {
    List<MarkerWithRenderSettings> markers = [];
    final image = await _getImageBytes();

    // Create new markers at the given coordinates.
    Marker marker1 = Marker();
    marker1.add(Coordinates(
        latitude: _coordinates1.latitude, longitude: _coordinates1.longitude));
    Marker marker2 = Marker();
    marker2.add(Coordinates(
        latitude: _coordinates2.latitude, longitude: _coordinates2.longitude));

    MarkerRenderSettings settings = MarkerRenderSettings();

    // Set the image for the markers, specifying the image format.
    settings.image = GemImage(image: image, format: ImageFileFormat.png);
    markers.add(MarkerWithRenderSettings(marker1, settings));
    markers.add(MarkerWithRenderSettings(marker2, settings));

    // Add the list of markers on the map.
    _mapController.preferences.markers
        .sketches(MarkerType.point)
        .addList(markers);
    _onCenterCoordinatesButtonPressed();

    setState(() {
      _isMarkerShown = true;
    });
  }

  void _onCenterCoordinatesButtonPressed() {
    final middleCoordinate = Coordinates(
        latitude: (_coordinates1.latitude! + _coordinates2.latitude!) / 2,
        longitude: (_coordinates1.longitude! + _coordinates2.longitude!) / 2);

    // Create an animation (optional).
    final animation = GemAnimation(type: AnimationType.linear);

    // Use the map controller to center on coordinates.
    _mapController.centerOnCoordinates(middleCoordinate, animation: animation);
  }

  void _clearMarkers() {
    // Clear markers from map.
    _mapController.preferences.markers.sketches(MarkerType.point).clear();

    setState(() {
      _isMarkerShown = false;
    });
  }

  Future<Uint8List> _getImageBytes() async {
    final ByteData data = await rootBundle.load('assets/custom_icon.png');
    return data.buffer.asUint8List();
  }
}
