// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

// ignore_for_file: avoid_print

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/search.dart';

import 'package:flutter/material.dart' hide Animation;

import 'dart:async';

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
      title: 'Address Search',
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
        title: const Text(
          'Address Search',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _onSearchButtonPressed(context).then((value) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                }
              });
            },
            icon: const Icon(Icons.search, color: Colors.white),
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

  // The callback for when map is ready to use
  void _onMapCreated(GemMapController controller) {
    // Save controller for further usage
    _mapController = controller;
  }

  Future<void> _onSearchButtonPressed(BuildContext context) async {
    _showSnackBar(context, message: "Search is in progress.");

    // Predefined landmark for Spain.
    final countryLandmark = GuidedAddressSearchService.getCountryLevelItem(
      'ESP',
    )!;
    print('Country: ${countryLandmark.name}');

    // Use the address search to get a landmark for a city in Spain (e.g., Barcelona).
    final cityLandmark = await _searchAddress(
      landmark: countryLandmark,
      detailLevel: AddressDetailLevel.city,
      text: 'Barcelona',
    );
    if (cityLandmark == null) return;
    print('City: ${cityLandmark.name}');

    // Use the address search to get a predefined street's landmark in the city (e.g., Carrer de Mallorca).
    final streetLandmark = await _searchAddress(
      landmark: cityLandmark,
      detailLevel: AddressDetailLevel.street,
      text: 'Carrer de Mallorca',
    );
    if (streetLandmark == null) return;
    print('Street: ${streetLandmark.name}');

    // Use the address search to get a predefined house number's landmark on the street (e.g., House Number 401).
    final houseNumberLandmark = await _searchAddress(
      landmark: streetLandmark,
      detailLevel: AddressDetailLevel.houseNumber,
      text: '401',
    );
    if (houseNumberLandmark == null) return;
    print('House number: ${houseNumberLandmark.name}');

    // Center the map on the final result.
    _presentLandmark(houseNumberLandmark);
  }

  void _presentLandmark(Landmark landmark) {
    // Highlight the landmark on the map.
    _mapController.activateHighlight([landmark]);

    // Create an animation (optional).
    final animation = GemAnimation(type: AnimationType.linear);

    // Use the map controller to center on coordinates.
    _mapController.centerOnCoordinates(
      landmark.coordinates,
      animation: animation,
      zoomLevel: 50,
    );
  }

  // Address search method.
  Future<Landmark?> _searchAddress({
    required Landmark landmark,
    required AddressDetailLevel detailLevel,
    required String text,
  }) async {
    final completer = Completer<Landmark?>();

    // Calling the address search SDK method.
    // (err, results) - is a callback function that gets called when the search is finished.
    // err is an error enum, results is a list of landmarks.
    GuidedAddressSearchService.search(text, landmark, detailLevel, (
      err,
      results,
    ) {
      // If there is an error, the method will return a null list.
      if (err != GemError.success && err != GemError.reducedResult ||
          results.isEmpty) {
        completer.complete(null);
        return;
      }

      completer.complete(results.first);
    });

    return completer.future;
  }

  // Show a snackbar indicating that the search is in progress.
  void _showSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(hours: 1),
  }) {
    final snackBar = SnackBar(content: Text(message), duration: duration);

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
