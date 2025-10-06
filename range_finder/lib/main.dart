// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'dart:math';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';

import 'ranges_panel.dart';

import 'package:flutter/material.dart';

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
      title: 'Range Finder',
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

  Landmark? _focusedLandmark;

  @override
  void dispose() {
    GemKit.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: Colors.deepPurple[900],
        title: const Text(
          'Range Finder',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          GemMap(
            key: ValueKey("GemMap"),
            onMapCreated: _onMapCreated,
            appAuthorization: projectApiToken,
          ),
          if (_focusedLandmark != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: RangesPanel(
                onCancelTap: _onCancelLandmarkPanelTap,
                landmark: _focusedLandmark!,
                mapController: _mapController,
              ),
            ),
        ],
      ),
    );
  }

  // The callback for when map is ready to use.
  Future<void> _onMapCreated(GemMapController controller) async {
    // Save controller for further usage.
    _mapController = controller;

    // Register route tap gesture callback.
    await _registerLandmarkTapCallback();
  }

  Future<void> _registerLandmarkTapCallback() async {
    _mapController.registerOnTouch((pos) async {
      // Select the object at the tap position.
      await _mapController.setCursorScreenPosition(pos);

      // Get the selected landmarks.
      final landmarks = _mapController.cursorSelectionLandmarks();

      // Reset the cursor position back to middle of the screen
      await _mapController.resetMapSelection();

      // Check if there is a selected Landmark.
      if (landmarks.isEmpty) {
        return;
      }

      // Highlight the selected landmark.
      _mapController.activateHighlight(landmarks);

      final lmk = landmarks[0];
      setState(() {
        _focusedLandmark = lmk;
      });

      // Use the map controller to center on coordinates.
      _mapController.centerOnCoordinates(
        lmk.coordinates,
        zoomLevel: 70,
        screenPosition: Point<int>(
          _mapController.viewport.width ~/ 2,
          _mapController.viewport.height ~/ 3,
        ),
      );
    });
  }

  void _onCancelLandmarkPanelTap() {
    // Remove landmark highlights from the map.
    _mapController.deactivateAllHighlights();
    _mapController.preferences.routes.clear();

    setState(() {
      _focusedLandmark = null;
    });
  }
}
