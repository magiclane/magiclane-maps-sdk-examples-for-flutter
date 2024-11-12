// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

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
        title:
            const Text('Range Finder', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          GemMap(
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
                ))
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
    _mapController.registerTouchCallback((pos) async {
      // Select the object at the tap position.
      await _mapController.setCursorScreenPosition(pos);

      // Get the selected landmarks.
      final landmarks = _mapController.cursorSelectionLandmarks();

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
      _mapController.centerOnCoordinates(lmk.coordinates);
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
