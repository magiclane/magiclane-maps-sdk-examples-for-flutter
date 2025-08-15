// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:gem_kit/core.dart';
import 'package:gem_kit/landmark_store.dart';
import 'package:gem_kit/map.dart';

import 'package:flutter/material.dart' hide Route;
import 'package:gem_kit/search.dart';
import 'package:import_custom_landmarks/landmark_panel.dart';
import 'package:import_custom_landmarks/search_page.dart';
import 'package:import_custom_landmarks/utils.dart';

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
      title: 'Import custom landmarks',
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
  late SearchPreferences preferences;
  bool isStoreCreated = false;

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
          "Import custom landmarks",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: addLandmarkStore,
            icon: const Icon(Icons.publish, color: Colors.white),
          ),
          if (isStoreCreated)
            IconButton(
              onPressed: () => _onSearchButtonPressed(context, preferences),
              icon: const Icon(Icons.search, color: Colors.white),
            ),
        ],
      ),
      body: Stack(
        children: [
          GemMap(
            key: ValueKey("GemMap"),
            onMapCreated: _onMapCreated,
            appAuthorization: projectApiToken,
          ),
          if (_focusedLandmark != null)
            Positioned(
              bottom: 30,
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

  void _onMapCreated(GemMapController controller) {
    _mapController = controller;
    _registerLandmarkTapCallback();
  }

  Future<int?> _importLandmarks() async {
    final completer = Completer<bool>();

    final file = await assetToUint8List('assets/airports_europe.kml');

    final store = LandmarkStoreService.createLandmarkStore('archies_europe');
    //Ensure the store is empty before importing
    store.removeAllLandmarks();

    final img = await assetToUint8List('assets/KMLCategory.png');

    store.importLandmarksWithDataBuffer(
      buffer: file,
      format: LandmarkFileFormat.kml,
      image: Img(img),
      onComplete: (err) {
        if (err != GemError.success) {
          completer.complete(false);
        } else {
          completer.complete(true);
        }
      },
      categoryId: -1,
    );

    final res = await completer.future;
    if (res) {
      return store.id;
    } else {
      LandmarkStoreService.removeLandmarkStore(store.id);
      throw "Error importing landmarks";
    }
  }

  void addLandmarkStore() async {
    final id = await _importLandmarks();
    final store = LandmarkStoreService.getLandmarkStoreById(id!);

    _mapController.preferences.lmks.add(store!);

    _mapController.centerOnCoordinates(
      Coordinates(latitude: 53.70762, longitude: -1.61112),
      screenPosition: Point(
        _mapController.viewport.width ~/ 2,
        _mapController.viewport.height ~/ 2,
      ),
      zoomLevel: 25,
    );

    // Add the store to the search preferences
    preferences = SearchPreferences();
    preferences.landmarks.add(store);

    // If no results from the map POIs should be returned then searchMapPOIs should be set to false
    preferences.searchMapPOIs = false;

    // If no results from the addresses should be returned then searchAddresses should be set to false
    preferences.searchAddresses = false;

    setState(() {
      isStoreCreated = true;
    });
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
        _highlightLandmark(landmarks);
        return;
      }

      // Get the selected streets.
      final streets = _mapController.cursorSelectionStreets();

      // Check if there is a selected street.
      if (streets.isNotEmpty) {
        _highlightLandmark(streets);
        return;
      }

      final coordinates = _mapController.transformScreenToWgs(
        Point<int>(pos.x, pos.y),
      );

      // If no landmark was found, we create one.
      final lmk = Landmark.withCoordinates(coordinates);
      lmk.name = '${coordinates.latitude} ${coordinates.longitude}';
      lmk.setImageFromIcon(GemIcon.searchResultsPin);

      _highlightLandmark([lmk]);
    });
  }

  void _highlightLandmark(List<Landmark> landmarks) {
    final settings = HighlightRenderSettings(
      options: {
        HighlightOptions.showLandmark,
        HighlightOptions.showContour,
        HighlightOptions.overlap,
      },
    );
    // Highlight the landmark on the map.
    _mapController.activateHighlight(landmarks, renderSettings: settings);

    final lmk = landmarks[0];
    setState(() {
      _focusedLandmark = lmk;
    });

    _mapController.centerOnCoordinates(
      lmk.coordinates,
      screenPosition: Point(
        _mapController.viewport.width ~/ 2,
        _mapController.viewport.height ~/ 2,
      ),
      zoomLevel: 50,
    );
  }

  void _onCancelLandmarkPanelTap() {
    _mapController.deactivateAllHighlights();

    setState(() {
      _focusedLandmark = null;
    });
  }

  // Custom method for navigating to search screen
  void _onSearchButtonPressed(
    BuildContext context,
    SearchPreferences preferences,
  ) async {
    // Navigating to search screen. The result will be the selected search result(Landmark)
    final result = await Navigator.of(context).push(
      MaterialPageRoute<dynamic>(
        builder: (context) => SearchPage(
          coordinates: Coordinates(latitude: 53.70762, longitude: -1.61112),
          preferences: preferences,
        ),
      ),
    );

    if (result is Landmark) {
      // Activating the highlight
      _mapController.activateHighlight([
        result,
      ], renderSettings: HighlightRenderSettings());

      // Centering the map on the desired coordinates
      _mapController.centerOnCoordinates(result.coordinates, zoomLevel: 70);
    }
  }
}
