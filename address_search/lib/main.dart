// ignore_for_file: avoid_print

import 'dart:async';

import 'package:gem_kit/api/gem_coordinates.dart';
import 'package:gem_kit/api/gem_guidedaddresssearch.dart';
import 'package:gem_kit/api/gem_landmark.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/d3Scene.dart';
import 'package:gem_kit/gem_kit_basic.dart';
import 'package:gem_kit/gem_kit_platform_interface.dart';

import 'package:flutter/material.dart';

void main() {
  const token = "YOUR_API_TOKEN";
  GemKitPlatform.instance.loadNative().then((value) {
    SdkSettings.setAppAuthorization(token);
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
  void initState() {
    super.initState();
  }

  // The callback for when map is ready to use
  _onMapCreatedCallback(GemMapController controller) async {
    // Save controller for further usage
    _mapController = controller;
  }

  _onPressed(BuildContext context) async {
    // Predefined landmark for Spain
    Landmark countryLandmark = GuidedAddressSearchService.getCountryLevelItem('ESP');
    print('country: ${countryLandmark.getName()}');

    // Use the address search to get a landmark for a city in Spain (e.g., Barcelona)
    Landmark? cityLandmark = await _searchAddress(countryLandmark, EAddressDetailLevel.AD_City, 'Barcelona');
    if (cityLandmark == null) return;
    print('city: ${cityLandmark.getName()}');

    // Use the address search to get a predefined street's landmark in the city (e.g., Carrer de Mallorca)
    Landmark? streetLandmark = await _searchAddress(cityLandmark, EAddressDetailLevel.AD_Street, 'Carrer de Mallorca');
    if (streetLandmark == null) return;
    print('street: ${streetLandmark.getName()}');

    // Use the address search to get a predefined house number's landmark on the street (e.g., House Number 401)
    Landmark? houseNumberLandmark = await _searchAddress(streetLandmark, EAddressDetailLevel.AD_HouseNumber, '401');
    if (houseNumberLandmark == null) return;

    print('house: ${houseNumberLandmark.getName()}');

    // Centering the map on the final result
    _centerOnCoordinates(houseNumberLandmark.getCoordinates());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple[900],
        foregroundColor: Colors.white,
        onPressed: () => _onPressed(context),
        child: const Icon(Icons.search),
      ),
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Stack(
          children: [
            GemMap(
              onMapCreated: _onMapCreatedCallback,
            ),
          ],
        ),
      ),
    );
  }

  _centerOnCoordinates(Coordinates coordinates) {
    // Create an animation (optional)
    final animation = GemAnimation(type: EAnimation.AnimationLinear);

    // Use the map controller to center on coordinates
    _mapController.centerOnCoordinates(coordinates, animation: animation);
  }

  // Address search method
  Future<Landmark?> _searchAddress(Landmark landmark, EAddressDetailLevel detailLevel, String text) async {
    Completer<List<Landmark>> completer = Completer<List<Landmark>>();

    // Calling the address search method from the sdk.
    // (err, results) - is a callback function that calls when the computing is done.
    // err is an error code, results is a list of landmarks
    GuidedAddressSearchService.search(text, landmark, detailLevel, (err, results) async {
      // If there is an error or there aren't any results, the method will return an empty list.
      if ((err != GemError.success && err != GemError.reducedResult) || results == null) {
        completer.complete([]);
        return;
      }
      List<Landmark> searchResults = [];

      for (final gemLmk in results) {
        searchResults.add(gemLmk);
      }

      if (!completer.isCompleted) completer.complete(searchResults);
    });

    final result = await completer.future;
    if (result.isEmpty) {
      print('$text not found');
    }
    return result.firstOrNull;
  }
}
