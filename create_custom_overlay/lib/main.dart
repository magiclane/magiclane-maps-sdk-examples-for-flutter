// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';

import 'package:flutter/material.dart' hide Route;
import 'package:magiclane_maps_flutter/search.dart';
import 'package:create_custom_overlay/overlay_item_panel.dart';
import 'package:create_custom_overlay/search_page.dart';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');
const overlayUid = 0; // <-- Replace with your overlay UID

void main() {
  print(pid);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, title: 'Create custom overlay', home: MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late GemMapController _mapController;
  OverlayItem? _focusedOverlayItem;
  late SearchPreferences preferences;
  bool isMapApplied = false;

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
        title: const Text("Create custom overlay", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: applyStyle,
            icon: const Icon(Icons.publish, color: Colors.white),
          ),
          if (isMapApplied)
            IconButton(
              onPressed: () => _onSearchButtonPressed(context, preferences),
              icon: const Icon(Icons.search, color: Colors.white),
            ),
        ],
      ),
      body: Stack(
        children: [
          GemMap(key: ValueKey("GemMap"), onMapCreated: _onMapCreated, appAuthorization: projectApiToken),
          if (_focusedOverlayItem != null)
            Positioned(
              bottom: 30,
              child: OverlayItemPanel(onCancelTap: _onCancelOverlayItemPanelTap, overlayItem: _focusedOverlayItem!),
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

  void applyStyle() async {
    // Import asset style data
    // The style containing custom overlay items from York should be added by the user in the assets folder of the project.
    final assetStyleData = await rootBundle.load('assets/style_with_data.style');
    final assetStyleBytes = assetStyleData.buffer.asUint8List();

    // Apply the style to the map
    _mapController.preferences.setMapStyleByBuffer(assetStyleBytes);

    // Center to the York region containing custom overlay items from the imported style
    RectangleGeographicArea yorkArea = RectangleGeographicArea(
      topLeft: Coordinates(latitude: 54.0001, longitude: -1.1678),
      bottomRight: Coordinates(latitude: 53.9130, longitude: -1.0015),
    );
    _mapController.centerOnArea(yorkArea);

    // Add the overlay to the search preferences
    preferences = SearchPreferences();

    // Make sure the overlays are loaded
    await _awaitOverlaysReady();

    // Add the overlay to the search preferences
    preferences.overlays.add(overlayUid);

    // If no results from the map POIs should be returned then searchMapPOIs should be set to false
    preferences.searchMapPOIs = false;

    // If no results from the addresses should be returned then searchAddresses should be set to false
    preferences.searchAddresses = false;

    setState(() {
      isMapApplied = true;
    });
  }

  Future<void> _awaitOverlaysReady() async {
    Completer<void> completer = Completer<void>();
    OverlayService.getAvailableOverlays(
      onCompleteDownload: (GemError error) {
        if (error != GemError.success) {
          print("Error while getting overlays: $error");
        }
        completer.complete();
      },
    );
    await completer.future;
  }

  Future<void> _registerLandmarkTapCallback() async {
    _mapController.registerOnTouch((pos) async {
      // Select the object at the tap position.
      await _mapController.setCursorScreenPosition(pos);

      // Get the selected overlay items.
      final overlayItems = _mapController.cursorSelectionOverlayItems();

      // Reset the cursor position back to middle of the screen
      await _mapController.resetMapSelection();

      // Check if there is a selected OverlayItem.
      if (overlayItems.isNotEmpty) {
        _highlightOverlayItems(overlayItems);
        return;
      }
    });
  }

  void _highlightOverlayItems(List<OverlayItem> overlayItems) {
    final settings = HighlightRenderSettings(
      options: {HighlightOptions.showLandmark, HighlightOptions.showContour, HighlightOptions.overlap},
    );
    // Highlight the overlay item on the map.
    _mapController.activateHighlightOverlayItems(overlayItems, renderSettings: settings);

    final overlay = overlayItems[0];
    setState(() {
      _focusedOverlayItem = overlay;
    });

    // Wait for a short duration before centering the map, otherwise the map tile
    // will not be valid and OverlayItem previewData will be incorrect
    Future.delayed(Duration(milliseconds: 500), () {
      _mapController.centerOnCoordinates(overlay.coordinates);
    });
  }

  void _onCancelOverlayItemPanelTap() {
    _mapController.deactivateAllHighlights();

    setState(() {
      _focusedOverlayItem = null;
    });
  }

  // Custom method for navigating to search screen
  void _onSearchButtonPressed(BuildContext context, SearchPreferences preferences) async {
    // Navigating to search screen. The result will be the selected search result(OverlayItem)
    final result = await Navigator.of(context).push(
      MaterialPageRoute<dynamic>(
        builder: (context) =>
            SearchPage(coordinates: Coordinates.fromLatLong(53.9617, -1.0779), preferences: preferences),
      ),
    );

    if (result is OverlayItem) {
      _mapController.centerOnCoordinates(result.coordinates, zoomLevel: 70);
    }
  }
}
