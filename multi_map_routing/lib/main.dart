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
      title: 'Multi Map Routing',
      debugShowCheckedModeBanner: false,
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
        title: const Text(
          'Multi Map Routing',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: _removeRoutes,
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => _onBuildRouteButtonPressed(true),
            icon: const Icon(Icons.route, color: Colors.white),
          ),
          IconButton(
            onPressed: () => _onBuildRouteButtonPressed(false),
            icon: const Icon(Icons.route, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GemMap(
                key: ValueKey("GemMap"),
                onMapCreated: _onMap1Created,
                appAuthorization: projectApiToken,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GemMap(onMapCreated: _onMap2Created),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(hours: 1),
  }) {
    final snackBar = SnackBar(content: Text(message), duration: duration);

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
      final departure = Landmark.withLatLng(
        latitude: 37.77903,
        longitude: -122.41991,
      );

      // Define the destination.
      final destination = Landmark.withLatLng(
        latitude: 37.33619,
        longitude: -121.89058,
      );

      waypoints.add(departure);
      waypoints.add(destination);
    } else {
      // Define the departure.
      final departure = Landmark.withLatLng(
        latitude: 51.50732,
        longitude: -0.12765,
      );

      // Define the destination.
      final destination = Landmark.withLatLng(
        latitude: 51.27483,
        longitude: 0.52316,
      );

      waypoints.add(departure);
      waypoints.add(destination);
    }

    // Define the route preferences.
    final routePreferences = RoutePreferences();

    _showSnackBar(
      context,
      message: isFirstMap
          ? 'The first route is calculating.'
          : 'The second route is calculating.',
    );

    // Calling the calculateRoute SDK method.
    // (err, results) - is a callback function that gets called when the route computing is finished.
    // err is an error enum, results is a list of routes.
    if (isFirstMap) {
      _routingHandler1 = RoutingService.calculateRoute(
        waypoints,
        routePreferences,
        (err, routes) => _onRouteBuiltFinished(err, routes, true),
      );
    } else {
      _routingHandler2 = RoutingService.calculateRoute(
        waypoints,
        routePreferences,
        (err, routes) => _onRouteBuiltFinished(err, routes, false),
      );
    }
  }

  void _onRouteBuiltFinished(
    GemError err,
    List<Route>? routes,
    bool isFirstMap,
  ) {
    // If the route calculation is finished, we don't have a progress listener anymore.
    if (isFirstMap) {
      _routingHandler1 = null;
    } else {
      _routingHandler2 = null;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    if (_routingHandler1 != null) {
      _showSnackBar(context, message: 'The first route is calculating.');
    }
    if (_routingHandler2 != null) {
      _showSnackBar(context, message: 'The second route is calculating.');
    }

    // If there aren't any errors, we display the routes.
    if (err == GemError.success) {
      // Get the routes collection from map preferences.
      final routesMap =
          (isFirstMap
                  ? _mapController1.preferences
                  : _mapController2.preferences)
              .routes;

      // Display the routes on map.
      for (final route in routes!) {
        routesMap.add(route, route == routes.first, label: getMapLabel(route));
      }

      // Center the camera on routes.
      if (isFirstMap) {
        _mapController1.centerOnRoutes(routes: routes);
      } else {
        _mapController2.centerOnRoutes(routes: routes);
      }
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

String getMapLabel(Route route) {
  return '${convertDistance(route.getTimeDistance().totalDistanceM)} \n${convertDuration(route.getTimeDistance().totalTimeS)}';
}

// Utility function to convert the meters distance into a suitable format.
String convertDistance(int meters) {
  if (meters >= 1000) {
    double kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(1)} km';
  } else {
    return '${meters.toString()} m';
  }
}

// Utility function to convert the seconds duration into a suitable format.
String convertDuration(int seconds) {
  int hours = seconds ~/ 3600; // Number of whole hours
  int minutes = (seconds % 3600) ~/ 60; // Number of whole minutes

  String hoursText = (hours > 0) ? '$hours h ' : ''; // Hours text
  String minutesText = '$minutes min'; // Minutes text

  return hoursText + minutesText;
}
