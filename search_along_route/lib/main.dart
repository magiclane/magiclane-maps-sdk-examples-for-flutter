// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

// ignore_for_file: avoid_print

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:gem_kit/navigation.dart';
import 'package:gem_kit/routing.dart';
import 'package:gem_kit/search.dart';

import 'package:flutter/material.dart' hide Route;

void main() {
  const projectApiToken = String.fromEnvironment('GEM_TOKEN');

  GemKit.initialize(appAuthorization: projectApiToken);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Search Along Route',
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

  bool _isSimulationActive = false;
  bool _areRoutesBuilt = false;

  // We use the handler to cancel the route calculation.
  TaskHandler? _routingHandler;

  // We use the handler to cancel the navigation.
  TaskHandler? _navigationHandler;

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
        title: const Text("Search Along Route", style: TextStyle(color: Colors.white)),
        leading: Row(
          children: [
            if (_areRoutesBuilt)
              IconButton(
                onPressed: _searchAlongRoute,
                icon: const Icon(Icons.search, color: Colors.white),
              ),
          ],
        ),
        actions: [
          if (!_isSimulationActive && _areRoutesBuilt)
            IconButton(
              onPressed: _startSimulation,
              icon: const Icon(Icons.play_arrow, color: Colors.white),
            ),
          if (_isSimulationActive)
            IconButton(
              onPressed: _stopSimulation,
              icon: const Icon(
                Icons.stop,
                color: Colors.white,
              ),
            ),
          if (!_areRoutesBuilt)
            IconButton(
              onPressed: () => _onBuildRouteButtonPressed(),
              icon: const Icon(
                Icons.route,
                color: Colors.white,
              ),
            ),
        ],
      ),
      body: GemMap(
        onMapCreated: _onMapCreated,
      ),
    );
  }

  void _onMapCreated(GemMapController controller) {
    _mapController = controller;
  }

  // Compute & show route.
  Future<void> _onBuildRouteButtonPressed() async {
    // Define the departure.
    final departureLandmark = Landmark();
    departureLandmark.coordinates = Coordinates(latitude: 37.77903, longitude: -122.41991);

    // Define the destination.
    final destinationLandmark = Landmark();
    destinationLandmark.coordinates = Coordinates(latitude: 37.33619, longitude: -121.89058);

    // Define the route preferences.
    final routePreferences = RoutePreferences();
    _showSnackBar(context);

    _routingHandler =
        RoutingService.calculateRoute([departureLandmark, destinationLandmark], routePreferences, (err, routes) async {
      // If the route calculation is finished, we don't have a progress listener anymore.
      _routingHandler = null;

      ScaffoldMessenger.of(context).clearSnackBars();

      // If there is an error, we return from this callback.
      if (err != GemError.success) {
        setState(() {
          _areRoutesBuilt = false;
        });
        return;
      }
      // Get the routes collection from map preferences.
      final routesMap = _mapController.preferences.routes;

      // Select the first route as the main one.
      final mainRoute = routes!.first;

      // Display the routes on map.
      for (final route in routes) {
        routesMap.add(route, route == mainRoute, label: route.getMapLabel());
      }

      _mapController.centerOnRoute(mainRoute);
    });
    setState(() {
      _areRoutesBuilt = true;
    });
  }

  // Start simulated navigation.
  void _startSimulation() {
    if (_isSimulationActive) return;
    if (!_areRoutesBuilt) return;

    // Get the main route from map routes collection;
    final routes = _mapController.preferences.routes;
    final mainRoute = routes.mainRoute;
    _navigationHandler = NavigationService.startSimulation(mainRoute, speedMultiplier: 2, (type, instruction) {
      if (type == NavigationEventType.destinationReached || type == NavigationEventType.error) {
        // If the navigation has ended or if and error occured while navigating, remove routes.
        setState(() {
          _isSimulationActive = false;
          _cancelRoute();
        });
        return;
      }
    });

    // Set the camera to follow position.
    _mapController.startFollowingPosition();

    setState(() {
      _isSimulationActive = true;
    });
  }

  void _cancelRoute() {
    // Remove the routes from map.
    _mapController.preferences.routes.clear();

    if (_routingHandler != null) {
      // Cancel the navigation.
      RoutingService.cancelRoute(_routingHandler!);
      _routingHandler = null;
    }

    setState(() {
      _areRoutesBuilt = false;
    });
  }

  // Stop simulated navigation.
  void _stopSimulation() {
    // Cancel the navigation.
    NavigationService.cancelNavigation(_navigationHandler!);
    _navigationHandler = null;

    _cancelRoute();

    setState(() {
      _isSimulationActive = false;
      _areRoutesBuilt = false;
    });
  }

  // Search along route.
  void _searchAlongRoute() {
    if (!_areRoutesBuilt) return;

    final routes = _mapController.preferences.routes;
    final mainRoute = routes.mainRoute;

    // Calling the search along route SDK method.
    // (err, results) - is a callback function that gets called when the search is finished.
    // err is an error enum, results is a list of landmarks.
    SearchService.searchAlongRoute(mainRoute, (err, results) {
      if (err != GemError.success || results == null) {
        print("SearchAlongRoute - no results found");
        return;
      }

      print("SearchAlongRoute - ${results.length} results:");
      for (final Landmark landmark in results) {
        final landmarkName = landmark.name;
        print("SearchAlongRoute: $landmarkName");
      }
    });
  }

  // Method to show message in case calculate route is not finished
  void _showSnackBar(BuildContext context) {
    const snackBar = SnackBar(
      content: Text("The route is calculating."),
      duration: Duration(hours: 1),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

// Define an extension for route for calculating the route label which will be displayed on map.
extension RouteExtension on Route {
  String getMapLabel() {
    final totalDistance = timeDistance.unrestrictedDistanceM + timeDistance.restrictedDistanceM;
    final totalDuration = timeDistance.unrestrictedTimeS + timeDistance.restrictedTimeS;

    return '${_convertDistance(totalDistance)} \n${_convertDuration(totalDuration)}';
  }

  // Utility function to convert the meters distance into a suitable format.
  String _convertDistance(int meters) {
    if (meters >= 1000) {
      double kilometers = meters / 1000;
      return '${kilometers.toStringAsFixed(1)} km';
    } else {
      return '${meters.toString()} m';
    }
  }

  // Utility function to convert the seconds duration into a suitable format.
  String _convertDuration(int seconds) {
    int hours = seconds ~/ 3600; // Number of whole hours
    int minutes = (seconds % 3600) ~/ 60; // Number of whole minutes

    String hoursText = (hours > 0) ? '$hours h ' : ''; // Hours text
    String minutesText = '$minutes min'; // Minutes text

    return hoursText + minutesText;
  }
}
