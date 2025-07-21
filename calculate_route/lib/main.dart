// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:gem_kit/routing.dart';

import 'package:flutter/material.dart' hide Route;

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
      title: 'Calculate Route',
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
        title: const Text(
          'Calculate Route',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // Routes are not built.
          if (_routingHandler == null && _routes == null)
            IconButton(
              onPressed: () => _onBuildRouteButtonPressed(context),
              icon: const Icon(Icons.route, color: Colors.white),
            ),
          // Routes calculating is in progress.
          if (_routingHandler != null)
            IconButton(
              onPressed: () => _onCancelRouteButtonPressed(),
              icon: const Icon(Icons.stop, color: Colors.white),
            ),
          // Routes calculating is finished.
          if (_routes != null)
            IconButton(
              onPressed: () => _onClearRoutesButtonPressed(),
              icon: const Icon(Icons.clear, color: Colors.white),
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

  // The callback for when map is ready to use.
  Future<void> _onMapCreated(GemMapController controller) async {
    // Save controller for further usage.
    _mapController = controller;

    // Register route tap gesture callback.
    await _registerRouteTapCallback();
  }

  void _onBuildRouteButtonPressed(BuildContext context) {
    // Define the departure.
    final departureLandmark = Landmark.withLatLng(
      latitude: 48.85682,
      longitude: 2.34375,
    );

    // Define the destination.
    final destinationLandmark = Landmark.withLatLng(
      latitude: 50.84644,
      longitude: 4.34587,
    );

    // Define the route preferences.
    final routePreferences = RoutePreferences();

    _showSnackBar(context, message: "The route is being calculated.");

    // Calling the calculateRoute SDK method.
    // (err, results) - is a callback function that gets called when the route computing is finished.
    // err is an error enum, results is a list of routes.

    _routingHandler = RoutingService.calculateRoute(
      [departureLandmark, destinationLandmark],
      routePreferences,
      (err, routes) {
        // If the route calculation is finished, we don't have a progress listener anymore.
        _routingHandler = null;
        ScaffoldMessenger.of(context).clearSnackBars();

        // If there aren't any errors, we display the routes.
        if (err == GemError.success) {
          // Get the routes collection from map preferences.
          final routesMap = _mapController.preferences.routes;

          // Display the routes on map.
          for (final route in routes) {
            routesMap.add(
              route,
              route == routes.first,
              label: route.getMapLabel(),
            );
          }

          // Center the camera on routes.
          _mapController.centerOnRoutes(routes: routes);
          setState(() {
            _routes = routes;
          });
        }
      },
    );

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
  Future<void> _registerRouteTapCallback() async {
    // Register the generic map touch gesture.
    _mapController.registerTouchCallback((pos) async {
      // Select the map objects at gives position.
      await _mapController.setCursorScreenPosition(pos);

      // Get the selected routes.
      final routes = _mapController.cursorSelectionRoutes();

      // If there is  a route at position, we select it as the main one on the map.
      if (routes.isNotEmpty) {
        _mapController.preferences.routes.mainRoute = routes[0];
      }
    });
  }

  // Show a snackbar indicating that the route calculation is in progress.
  void _showSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(hours: 1),
  }) {
    final snackBar = SnackBar(content: Text(message), duration: duration);

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

// Define an extension for route for calculating the route label which will be displayed on map.
extension RouteExtension on Route {
  String getMapLabel() {
    final totalDistance =
        getTimeDistance().unrestrictedDistanceM +
        getTimeDistance().restrictedDistanceM;
    final totalDuration =
        getTimeDistance().unrestrictedTimeS + getTimeDistance().restrictedTimeS;

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
