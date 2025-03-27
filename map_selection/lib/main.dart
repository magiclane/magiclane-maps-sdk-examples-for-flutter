// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'landmark_panel.dart';

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
      title: 'Map Selection',
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
        backgroundColor: Colors.deepPurple[900],
        title: const Text(
          'Map Selection',
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
              child: LandmarkPanel(
                onCancelTap: _onCancelLandmarkPanelTap,
                landmark: _focusedLandmark!,
              ),
            ),
        ],
      ),
      resizeToAvoidBottomInset: false,
    );
  }

  // The callback for when map is ready to use.
  Future<void> _onMapCreated(GemMapController controller) async {
    // Save controller for further usage.
    _mapController = controller;

    // Listen for map landmark selection events.
    await _registerLandmarkTapCallback();
  }

  Future<void> _registerLandmarkTapCallback() async {
    _mapController.registerTouchCallback((pos) async {
      // Select the object at the tap position.
      await _mapController.setCursorScreenPosition(pos);

      // Get the selected landmarks.
      final landmarks = _mapController.cursorSelectionLandmarks();

      // Reset the cursor position back to middle of the screen
      await _mapController.resetMapSelection();

      // Check if there is a selected Landmark.
      if (landmarks.isNotEmpty) {
        // Highlight the selected landmark.
        _mapController.activateHighlight(landmarks);

        setState(() {
          _focusedLandmark = landmarks[0];
        });

        // Use the map controller to center on coordinates.
        _mapController.centerOnCoordinates(
          _focusedLandmark!.coordinates,
          zoomLevel: 60,
        );
      }
    });
  }

  void _onCancelLandmarkPanelTap() {
    // Remove landmark highlights from the map.
    _mapController.deactivateAllHighlights();

    setState(() {
      _focusedLandmark = null;
    });
  }
}
