// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:gem_kit/routing.dart';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');

void main() async {
  await GemKit.initialize(appAuthorization: projectApiToken);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Draw Roadblock',
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

  // The coordinate where the preview currently ends (acts as a cursor for preview path)
  UserRoadblockPathPreviewCoordinate? previewCursor;

  // List of permanent coordinates (user confirmed)
  List<Coordinates> permanentCoords = [];
  // List of preview (temporary) coordinates
  List<Coordinates> previewCoordsList = [];

  // Draw mode
  bool drawMode = false;

  /// Debouncer in order to calculate preview only after movement is stopped
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    GemKit.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        foregroundColor: Colors.white,
        title: const Text(
          "Draw Roadblock",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple[900],
        actions: [
          // Add temporary coordinates to permanent
          if (drawMode)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                permanentCoords = [...permanentCoords, ...previewCoordsList];
                previewCoordsList = [];
                _redrawPath();
              },
            ),
          // Draw mode activate button
          if (!drawMode)
            IconButton(
              icon: Icon(Icons.draw),
              onPressed: () {
                setState(() {
                  drawMode = true;
                  permanentCoords = [];
                  previewCursor = null;
                  previewCoordsList = [];
                });
                _handlePreviewPathUpdate(allowRecursive: false);
              },
            ),
          // Add roadblock by permanent coordinates and reset the draw mode and coordinates lists
          if (drawMode)
            IconButton(
              icon: Icon(Icons.check),
              onPressed: () {
                final roadblockResult =
                    TrafficService.addPersistentRoadblockByCoordinates(
                  coords: permanentCoords,
                  startTime: DateTime.now(),
                  expireTime: DateTime.now().add(const Duration(days: 1)),
                  transportMode: RouteTransportMode.car,
                  id: DateTime.now().toIso8601String(), // Unique identifier
                );

                setState(() {
                  drawMode = false;
                  permanentCoords = [];
                  previewCursor = null;
                  previewCoordsList = [];
                });

                // In case of error, show snackbar
                if (roadblockResult.second != GemError.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error ${roadblockResult.second} when adding roadblock.',
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }

                // Reset the coordinates
                permanentCoords = [];
                previewCoordsList = [];
                _redrawPath();
              },
            ),
          // Cancel draw mode
          if (drawMode)
            IconButton(
              icon: Icon(Icons.cancel),
              onPressed: () {
                setState(() {
                  drawMode = false;
                  permanentCoords = [];
                  previewCoordsList = [];
                });
                permanentCoords = [];
                previewCoordsList = [];
                previewCursor = null;
                _redrawPath();
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          GemMap(
            appAuthorization: projectApiToken,
            onMapCreated: _onMapCreated,
          ),
          // Mark the center of the viewport
          const Center(child: Icon(Icons.add, size: 32, color: Colors.black)),
        ],
      ),
    );
  }

  /// Called when the map is created. Registers the move callback for draw mode.
  void _onMapCreated(GemMapController controller) async {
    _mapController = controller;

    _mapController.registerMoveCallback((_, __) {
      if (!drawMode) return;

      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 100), () {
        _handlePreviewPathUpdate(allowRecursive: true);
      });
    });
  }

  /// Handles updating the preview path when the map moves.
  void _handlePreviewPathUpdate({required bool allowRecursive}) {
    final centerScreen = Point<int>(
      _mapController.viewport.width ~/ 2,
      _mapController.viewport.height ~/ 2,
    );
    final centerCoord = _mapController.transformScreenToWgs(centerScreen);

    // On first call, initialize permanentCoords with the center coordinate
    if (permanentCoords.isEmpty) {
      permanentCoords.add(centerCoord);
    }

    // If previewCursor is null, set it and return
    if (previewCursor == null) {
      previewCursor = UserRoadblockPathPreviewCoordinate.fromCoordinates(
        centerCoord,
      );
      return;
    }

    // Compute route coordinates from previous coordinates to new coordinates
    final (from, to, error) = TrafficService.getPersistentRoadblockPathPreview(
      from: previewCursor!,
      to: centerCoord,
      transportMode: RouteTransportMode.car,
    );

    if (error != GemError.success) {
      _resetPreviewPathOnError(allowRecursive);
      return;
    }

    _updatePreviewPath(from, to);
  }

  /// Resets the preview path and optionally retries if an error occurs.
  void _resetPreviewPathOnError(bool allowRecursive) {
    previewCoordsList = [];
    previewCursor = UserRoadblockPathPreviewCoordinate.fromCoordinates(
      permanentCoords.last,
    );
    _redrawPath();
    if (allowRecursive) {
      _handlePreviewPathUpdate(allowRecursive: false);
    }
  }

  /// Updates the preview path and redraws the map.
  void _updatePreviewPath(
    List<Coordinates> from,
    UserRoadblockPathPreviewCoordinate to,
  ) {
    previewCoordsList = [...previewCoordsList, ...from];
    previewCursor = to;
    _redrawPath();
  }

  /// Redraws the permanent and preview paths on the map.
  void _redrawPath() {
    final previewPath = Path.fromCoordinates(previewCoordsList);
    final permanentPath = Path.fromCoordinates(permanentCoords);
    _mapController.preferences.paths.clear();
    _mapController.preferences.paths.add(previewPath, colorInner: Colors.green);
    _mapController.preferences.paths.add(permanentPath, colorInner: Colors.red);
  }
}
