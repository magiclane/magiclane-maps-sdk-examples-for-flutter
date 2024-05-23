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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Build route example',
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

  // We use the handler to cancel the route calculation.
  TaskHandler? _routingHandler;

  List<Route>? _routes;

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
        title: const Text('Calculate Route', style: TextStyle(color: Colors.white)),
        actions: [
          // Routes are not built.
          if (_routingHandler == null && _routes == null)
            IconButton(
              onPressed: () => _onBuildRouteButtonPressed(context),
              icon: const Icon(
                Icons.route,
                color: Colors.white,
              ),
            ),
          // Routes calculating is in progress.
          if (_routingHandler != null)
            IconButton(
              onPressed: () => _onCancelRouteButtonPressed(),
              icon: const Icon(
                Icons.stop,
                color: Colors.white,
              ),
            ),
          // Routes calculating is finished.
          if (_routes != null)
            IconButton(
              onPressed: () => _onClearRoutesButtonPressed(),
              icon: const Icon(
                Icons.clear,
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

  // The callback for when map is ready to use.
  void _onMapCreated(GemMapController controller) {
    // Save controller for further usage.
    _mapController = controller;

    // Register route tap gesture callback.
    _registerRouteTapCallback();
  }

  void _onBuildRouteButtonPressed(BuildContext context) {
    // Define the departure.
    final departureLandmark = Landmark();
    departureLandmark.coordinates = Coordinates(latitude: 48.85682120481962, longitude: 2.343751354197309);

    // Define the destination.
    final destinationLandmark = Landmark();
    destinationLandmark.coordinates = Coordinates(latitude: 50.846442672966944, longitude: 4.345870353765759);

    // Define the route preferences.
    final routePreferences = RoutePreferences();

    _showSnackBar(context);

    // Calling the calculateRoute SDK method.
    // (err, results) - is a callback function that gets called when the route computing is finished.
    // err is an error enum, results is a list of routes.

    _routingHandler =
        RoutingService.calculateRoute([departureLandmark, destinationLandmark], routePreferences, (err, routes) {
      // If the route calculation is finished, we don't have a progress listener anymore.
      _routingHandler = null;

      ScaffoldMessenger.of(context).clearSnackBars();

      // If there is an error, we return from this callback.
      if (err != GemError.success) {
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

      // Center the camera on routes.
      _mapController.centerOnRoutes(routes);
      setState(() {
        _routes = routes;
      });
    });

    setState(() {});
  }

  void _onClearRoutesButtonPressed() {
    // Remove the routes from map.
    _mapController.preferences.routes.clear();

    setState(() {
      _routes = null;
    });
  }

  void _onCancelRouteButtonPressed() {
    // If we have a progress listener we cancel the route calculation.
    if (_routingHandler != null) {
      RoutingService.cancelRoute(_routingHandler!);
      setState(() {
        _routingHandler = null;
      });
    }
  }

  // In order to be able to select an alternative route, we have to register the route tap gesture callback.
  void _registerRouteTapCallback() {
    // Register the generic map touch gesture.
    _mapController.registerTouchCallback((pos) async {
      // Select the map objects at gives position.
      await _mapController.selectMapObjects(pos);

      // Get the selected routes.
      final routes = _mapController.cursorSelectionRoutes();

      // If there isn't any route at position, we return from this method.
      if (routes.isEmpty) {
        return;
      }

      // We take the first route as the selected.
      final route = routes[0];

      // We set the selected route as the main one on the map.
      _mapController.preferences.routes.mainRoute = route;
    });
  }

  // Show a snackbar indicating that the route calculation is in progress.
  void _showSnackBar(BuildContext context) {
    const snackBar = SnackBar(
      content: Text("The route is being calculating."),
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
