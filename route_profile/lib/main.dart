// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'dart:math';

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:gem_kit/routing.dart';

import 'package:flutter/material.dart' hide Route;

import 'elevation_chart.dart';
import 'route_profile_panel.dart';

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
      title: 'Route Profile',
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

  Route? _focusedRoute;

  final ElevationChartController _chartController = ElevationChartController();

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
          'Route Profile',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // Routes are not built.
          if (_routingHandler == null && _focusedRoute == null)
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
          if (_focusedRoute != null)
            IconButton(
              onPressed: () => _onClearRoutesButtonPressed(),
              icon: const Icon(Icons.clear, color: Colors.white),
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
          if (_focusedRoute != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: RouteProfilePanel(
                route: _focusedRoute!,
                mapController: _mapController,
                chartController: _chartController,
                centerOnRoute: () => _centerOnRoute([_focusedRoute!]),
              ),
            ),
        ],
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
      latitude: 46.59344,
      longitude: 7.91069,
    );

    // Define the destination.
    final destinationLandmark = Landmark.withLatLng(
      latitude: 46.55945,
      longitude: 7.89293,
    );

    // Define the route preferences.
    // Terrain profile has to be enabled for this example to work.
    final routePreferences = RoutePreferences(
      buildTerrainProfile: const BuildTerrainProfile(enable: true),
      transportMode: RouteTransportMode.pedestrian,
    );

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
              label: getMapLabel(route),
            );
          }

          // Center the camera on routes.
          _centerOnRoute(routes);
          setState(() {
            _focusedRoute = routes.first;
          });
        }
      },
    );

    setState(() {});
  }

  void _onClearRoutesButtonPressed() {
    _mapController.preferences.paths.clear();

    // Remove the routes from map.
    _mapController.preferences.routes.clear();

    setState(() {
      _focusedRoute = null;
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
    _mapController.registerOnTouch((pos) async {
      // Select the map objects at gives position.
      await _mapController.setCursorScreenPosition(pos);

      // Get the selected routes.
      final routes = _mapController.cursorSelectionRoutes();

      // If there is  a route at position, we select it as the main one on the map.
      if (routes.isNotEmpty) {
        _mapController.preferences.routes.mainRoute = routes.first;

        // Reset the highlight on the chart.
        if (_chartController.setCurrentHighlight != null) {
          _chartController.setCurrentHighlight!(0);
        }

        setState(() {
          _focusedRoute = routes.first;
        });

        // Center the camera on the main route.
        _centerOnRoute([_focusedRoute!]);
      }
    });
  }

  void _centerOnRoute(List<Route> route) {
    const appbarHeight = 50;
    const padding = 20;

    // Use the map controller to center on route above the panel.
    _mapController.centerOnRoutes(
      routes: route,
      screenRect: Rectangle<int>(
        0,
        (appbarHeight + padding * MediaQuery.of(context).devicePixelRatio)
            .toInt(),
        (MediaQuery.of(context).size.width *
                MediaQuery.of(context).devicePixelRatio)
            .toInt(),
        ((MediaQuery.of(context).size.height / 2 -
                    appbarHeight -
                    2 * padding * MediaQuery.of(context).devicePixelRatio) *
                MediaQuery.of(context).devicePixelRatio)
            .toInt(),
      ),
    );
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
