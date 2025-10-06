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
      title: 'Draw Shapes',
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
        title: const Text('Draw Shapes', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: _onPolylineButtonPressed,
            icon: const Icon(Icons.adjust, color: Colors.white),
          ),
          IconButton(
            onPressed: _onPolygonButtonPressed,
            icon: const Icon(Icons.change_history, color: Colors.white),
          ),
          IconButton(
            onPressed: _onPointsButtonPressed,
            icon: const Icon(Icons.more_horiz, color: Colors.white),
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

  // Method to draw and center on a polyline
  void _onPolylineButtonPressed() {
    // Create a marker collection
    final markerCollection = MarkerCollection(
      markerType: MarkerType.polyline,
      name: 'Polyline marker collection',
    );

    // Set coordinates of marker
    final marker = Marker();
    marker.setCoordinates([
      Coordinates(latitude: 52.360495, longitude: 4.936882),
      Coordinates(latitude: 52.360495, longitude: 4.836882),
    ]);
    markerCollection.add(marker);

    _showMarkerCollectionOnMap(markerCollection);
  }

  // Method to draw and center on a polygon
  void _onPolygonButtonPressed() {
    // Create a marker collection
    final markerCollection = MarkerCollection(
      markerType: MarkerType.polygon,
      name: 'Polygon marker collection',
    );

    // Set coordinates of marker
    final marker = Marker();
    marker.setCoordinates([
      Coordinates(latitude: 52.340234, longitude: 4.886882),
      Coordinates(latitude: 52.300495, longitude: 4.936882),
      Coordinates(latitude: 52.300495, longitude: 4.836882),
    ]);
    markerCollection.add(marker);

    _showMarkerCollectionOnMap(markerCollection);
  }

  // Method to draw and center on points
  void _onPointsButtonPressed() {
    // Create a marker collection
    final markerCollection = MarkerCollection(
      markerType: MarkerType.point,
      name: 'Points marker collection',
    );

    // Set coordinates of marker
    final marker = Marker();
    marker.setCoordinates([
      Coordinates(latitude: 52.380495, longitude: 4.930882),
      Coordinates(latitude: 52.380495, longitude: 4.900882),
      Coordinates(latitude: 52.380495, longitude: 4.870882),
      Coordinates(latitude: 52.380495, longitude: 4.840882),
    ]);
    markerCollection.add(marker);

    _showMarkerCollectionOnMap(markerCollection);
  }

  Future<void> _showMarkerCollectionOnMap(
    MarkerCollection markerCollection,
  ) async {
    final settings = MarkerCollectionRenderSettings();

    // Clear previous markers from the map
    await _mapController.preferences.markers.clear();

    // Show the current marker on map and center on it
    _mapController.preferences.markers.add(
      markerCollection,
      settings: settings,
    );
    _mapController.centerOnArea(markerCollection.area, zoomLevel: 50);
  }
}
