// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:gem_kit/routing.dart';

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
    return const MaterialApp(title: 'Multi Map Routing', debugShowCheckedModeBanner: false, home: MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late GemMapController _mapController1;
  late GemMapController _mapController2;

  // We use the handlers to cancel the route calculation.
  TaskHandler? _routingHandler1;
  TaskHandler? _routingHandler2;

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
        title: const Text('Multi Map Routing', style: TextStyle(color: Colors.white)),
        leading: IconButton(
            onPressed: _removeRoutes,
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            )),
        actions: [
          IconButton(
              onPressed: () => _onBuildRouteButtonPressed(true),
              icon: const Icon(
                Icons.route,
                color: Colors.white,
              )),
          IconButton(
              onPressed: () => _onBuildRouteButtonPressed(false),
              icon: const Icon(
                Icons.route,
                color: Colors.white,
              ))
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height / 2 - 50,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GemMap(
                onMapCreated: _onMap1Created,
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height / 2 - 50,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GemMap(
                onMapCreated: _onMap2Created,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to show message in case calculate route is not finished.
  void _showSnackBar(BuildContext context, int map) {
    String whichMap = map == 1 ? 'first' : 'second';
    final snackBar = SnackBar(
      content: Text("The $whichMap route is calculating."),
      duration: const Duration(hours: 1),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // The callback for when map 1 is ready to use.
  void _onMap1Created(GemMapController controller) {
    // Save controller for further usage.
    _mapController1 = controller;
  }

// The callback for when map 2  is ready to use.
  void _onMap2Created(GemMapController controller) {
    // Save controller for further usage.
    _mapController2 = controller;
  }

  void _onBuildRouteButtonPressed(bool isFirstMap) {
    final waypoints = <Landmark>[];
    if (isFirstMap) {
      // Define the departure.
      final departure = Landmark();
      departure.coordinates = Coordinates(latitude: 37.77903, longitude: -122.41991);

      // Define the destination.
      final destination = Landmark();
      destination.coordinates = Coordinates(latitude: 37.33619, longitude: -121.89058);

      waypoints.add(departure);
      waypoints.add(destination);
    } else {
      // Define the departure.
      final departure = Landmark();
      departure.coordinates = Coordinates(latitude: 51.50732, longitude: -0.12765);

      // Define the destination.
      final destination = Landmark();
      destination.coordinates = Coordinates(latitude: 51.27483, longitude: 0.52316);

      waypoints.add(departure);
      waypoints.add(destination);
    }

    // Define the route preferences.
    final routePreferences = RoutePreferences();

    _showSnackBar(context, isFirstMap ? 1 : 2);

    // Calling the calculateRoute SDK method.
    // (err, results) - is a callback function that gets called when the route computing is finished.
    // err is an error enum, results is a list of routes.
    if (isFirstMap) {
      _routingHandler1 = RoutingService.calculateRoute(
          waypoints, routePreferences, (err, routes) => _onRouteBuiltFinished(err, routes, true));
    } else {
      _routingHandler2 = RoutingService.calculateRoute(
          waypoints, routePreferences, (err, routes) => _onRouteBuiltFinished(err, routes, false));
    }
  }

  void _onRouteBuiltFinished(GemError err, List<Route>? routes, bool isFirstMap) {
    // If the route calculation is finished, we don't have a progress listener anymore.
    if (isFirstMap) {
      _routingHandler1 = null;
    } else {
      _routingHandler2 = null;
    }

    ScaffoldMessenger.of(context).clearSnackBars();

    // If there is an error, we return from this callback.
    if (err != GemError.success) {
      return;
    }

    // Get the routes collection from map preferences.
    final routesMap = (isFirstMap ? _mapController1.preferences : _mapController2.preferences).routes;

    // Select the first route as the main one.
    final mainRoute = routes!.first;

    // Display the routes on map.
    for (final route in routes) {
      routesMap.add(route, route == mainRoute, label: route.getMapLabel());
    }

    // Center the camera on routes.
    if (isFirstMap) {
      _mapController1.centerOnRoutes(routes);
    } else {
      _mapController2.centerOnRoutes(routes);
    }
  }

  void _removeRoutes() {
    // If we have a progress listener we cancel the route calculation.

    if (_routingHandler1 != null) {
      RoutingService.cancelRoute(_routingHandler1!);
      _routingHandler1 = null;
    }

    if (_routingHandler2 != null) {
      RoutingService.cancelRoute(_routingHandler2!);
      _routingHandler2 = null;
    }

    // Remove the routes from map.
    _mapController1.preferences.routes.clear();
    _mapController2.preferences.routes.clear();
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
