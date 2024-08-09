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

import 'elevation_chart.dart';
import 'route_profile_panel.dart';

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

  final LineAreaChartController _chartController = LineAreaChartController();

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
        title:
            const Text('Route Profile', style: TextStyle(color: Colors.white)),
        actions: [
          // Routes are not built.
          if (_routingHandler == null && _focusedRoute == null)
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
          if (_focusedRoute != null)
            IconButton(
              onPressed: () => _onClearRoutesButtonPressed(),
              icon: const Icon(
                Icons.clear,
                color: Colors.white,
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          GemMap(
            onMapCreated: _onMapCreated,
          ),
          if (_focusedRoute != null)
            Align(
                alignment: Alignment.bottomCenter,
                child: RouteProfilePanel(
                  route: _focusedRoute!,
                  mapController: _mapController,
                  chartController: _chartController,
                  centerOnRoute: () => _centerOnRoute([_focusedRoute!]),
                ))
        ],
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
    final departureLandmark =
        Landmark.withLatLng(latitude: 46.59344, longitude: 7.91069);

    // Define the destination.
    final destinationLandmark =
        Landmark.withLatLng(latitude: 46.55945, longitude: 7.89293);

    // Define the route preferences.
    // Terrain profile has to be enabled for this example to work.
    final routePreferences = RoutePreferences(
        buildTerrainProfile: const BuildTerrainProfile(enable: true),
        transportMode: RouteTransportMode.pedestrian);

    _showSnackBar(context, message: "The route is being calculated.");

    // Calling the calculateRoute SDK method.
    // (err, results) - is a callback function that gets called when the route computing is finished.
    // err is an error enum, results is a list of routes.

    _routingHandler = RoutingService.calculateRoute(
        [departureLandmark, destinationLandmark], routePreferences,
        (err, routes) {
      // If the route calculation is finished, we don't have a progress listener anymore.
      _routingHandler = null;
      ScaffoldMessenger.of(context).clearSnackBars();

      // If there aren't any errors, we display the routes.
      if (err == GemError.success) {
        // Get the routes collection from map preferences.
        final routesMap = _mapController.preferences.routes;

        // Display the routes on map.
        for (final route in routes!) {
          routesMap.add(route, route == routes.first,
              label: route.getMapLabel());
        }

        // Center the camera on routes.
        _centerOnRoute(routes);
        setState(() {
          _focusedRoute = routes.first;
        });
      }
    });

    setState(() {});
  }

  void _onClearRoutesButtonPressed() {
    _mapController.deactivateAllHighlights();

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
  void _registerRouteTapCallback() {
    // Register the generic map touch gesture.
    _mapController.registerTouchCallback((pos) async {
      // Select the map objects at gives position.
      _mapController.setCursorScreenPosition(pos);

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
        screenRect: RectType(
          x: 0,
          y: (appbarHeight + padding * MediaQuery.of(context).devicePixelRatio)
              .toInt(),
          width: (MediaQuery.of(context).size.width *
                  MediaQuery.of(context).devicePixelRatio)
              .toInt(),
          height: ((MediaQuery.of(context).size.height / 2 -
                      appbarHeight -
                      2 * padding * MediaQuery.of(context).devicePixelRatio) *
                  MediaQuery.of(context).devicePixelRatio)
              .toInt(),
        ));
  }

  // Show a snackbar indicating that the route calculation is in progress.
  void _showSnackBar(BuildContext context,
      {required String message, Duration duration = const Duration(hours: 1)}) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: duration,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

// Define an extension for route for calculating the route label which will be displayed on map.
extension RouteExtension on Route {
  String getMapLabel() {
    final totalDistance = getTimeDistance().unrestrictedDistanceM +
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
