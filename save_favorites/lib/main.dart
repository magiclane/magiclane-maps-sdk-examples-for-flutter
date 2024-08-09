// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'package:gem_kit/core.dart';
import 'package:gem_kit/landmark_store.dart';
import 'package:gem_kit/map.dart';

import 'favorites_page.dart';
import 'landmark_panel.dart';

import 'package:flutter/material.dart';

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
      title: 'Save Favorites',
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

  // LandmarkStore object to save Landmarks.
  late LandmarkStore? _favoritesStore;

  bool _isLandmarkFavorite = false;

  final favoritesStoreName = 'Favorites';

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
        title: const Text('Favourites', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
              onPressed: () => _onFavouritesButtonPressed(context),
              icon: const Icon(
                Icons.favorite,
                color: Colors.white,
              ))
        ],
      ),
      body: Stack(children: [
        GemMap(
          onMapCreated: _onMapCreated,
        ),
        if (_focusedLandmark != null)
          Positioned(
              bottom: 10,
              child: LandmarkPanel(
                onCancelTap: _onCancelLandmarkPanelTap,
                onFavoritesTap: _onFavoritesLandmarkPanelTap,
                isFavoriteLandmark: _isLandmarkFavorite,
                landmark: _focusedLandmark!,
              ))
      ]),
      resizeToAvoidBottomInset: false,
    );
  }

  // The callback for when map is ready to use.
  void _onMapCreated(GemMapController controller) {
    // Save controller for further usage.
    _mapController = controller;

    // Retrieves the LandmarkStore with the given name.
    _favoritesStore =
        LandmarkStoreService.getLandmarkStoreByName(favoritesStoreName);

    // If there is no LandmarkStore with this name, then create it.
    _favoritesStore ??=
        LandmarkStoreService.createLandmarkStore(favoritesStoreName);

    // Listen for map landmark selection events.
    _registerLandmarkTapCallback();
  }

  void _registerLandmarkTapCallback() {
    _mapController.registerTouchCallback((pos) async {
      // Select the object at the tap position.
      _mapController.setCursorScreenPosition(pos);

      // Get the selected landmarks.
      final landmarks = _mapController.cursorSelectionLandmarks();

      // Check if there is a selected Landmark.
      if (landmarks.isNotEmpty) {
        _highlightLandmarks(landmarks);
        return;
      }

      // Get the selected streets.
      final streets = _mapController.cursorSelectionStreets();

      // Check if there is a selected street.
      if (streets.isNotEmpty) {
        _highlightLandmarks(streets);
        return;
      }

      final coordinates = _mapController
          .transformScreenToWgs(XyType(x: pos.x as int, y: pos.y as int));
      if (coordinates == null) return;

      // If no landmark was found, we create one.
      final lmk = Landmark.withCoordinates(coordinates);
      lmk.name = '${coordinates.latitude} ${coordinates.longitude}';
      lmk.setImageFromIcon(GemIcon.searchResultsPin);

      _highlightLandmarks([lmk]);
    });
  }

  void _highlightLandmarks(List<Landmark> landmarks) {
    // Highlight the landmark on the map.
    _mapController.activateHighlight(landmarks);

    final lmk = landmarks[0];
    setState(() {
      _focusedLandmark = lmk;
    });

    _mapController.centerOnCoordinates(lmk.coordinates);

    _checkIfFavourite();
  }

  // Method to navigate to the Favourites Page.
  void _onFavouritesButtonPressed(BuildContext context) async {
    // Fetch landmarks from the store
    final favoritesList = _favoritesStore!.getLandmarks();

    // Navigating to favorites screen then the result will be the selected item in the list.
    final result = await Navigator.of(context).push(MaterialPageRoute<dynamic>(
      builder: (context) => FavoritesPage(landmarkList: favoritesList),
    ));

    if (result is Landmark) {
      // Highlight the landmark on the map.
      _mapController.activateHighlight([result],
          renderSettings: HighlightRenderSettings());

      // Centering the camera on landmark's coordinates.
      _mapController.centerOnCoordinates(result.coordinates);

      setState(() {
        _focusedLandmark = result;
      });
      _checkIfFavourite();
    }
  }

  void _onCancelLandmarkPanelTap() {
    // Remove landmark highlights from the map.
    _mapController.deactivateAllHighlights();

    setState(() {
      _focusedLandmark = null;
      _isLandmarkFavorite = false;
    });
  }

  void _onFavoritesLandmarkPanelTap() {
    _checkIfFavourite();

    if (_isLandmarkFavorite) {
      // Remove the landmark to the store.
      _favoritesStore!.removeLandmark(_focusedLandmark!);
    } else {
      // Add the landmark to the store.
      _favoritesStore!.addLandmark(_focusedLandmark!);
    }
    setState(() {
      _isLandmarkFavorite = !_isLandmarkFavorite;
    });
  }

  // Utility method to check if the highlighted landmark is favourite.
  void _checkIfFavourite() {
    final focusedLandmarkCoords = _focusedLandmark!.coordinates;
    final favourites = _favoritesStore!.getLandmarks();

    for (final lmk in favourites) {
      late Coordinates coords;
      coords = lmk.coordinates;

      if (focusedLandmarkCoords.latitude == coords.latitude &&
          focusedLandmarkCoords.longitude == coords.longitude) {
        setState(() {
          _isLandmarkFavorite = true;
        });
        return;
      }
    }

    setState(() {
      _isLandmarkFavorite = false;
    });
  }
}
