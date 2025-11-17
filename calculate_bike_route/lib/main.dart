// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:flutter/material.dart' hide Route;

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';

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
      title: 'Calculate Bike Route',
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
  BikeProfile? selectedBikeType;

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
          'Calculate Bike Route',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // Select the bike profile.
          IconButton(
            onPressed: () => _showPopupMenu(context),
            icon: const Icon(Icons.directions_bike, color: Colors.white),
          ),
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
      latitude: 52.36239785,
      longitude: 4.89891628,
    );

    // Define the destination.
    final destinationLandmark = Landmark.withLatLng(
      latitude: 52.3769534,
      longitude: 4.898427,
    );

    // Define the route preferences with selected bike type.
    final routePreferences = RoutePreferences(
      bikeProfile: BikeProfileElectricBikeProfile(
        profile: selectedBikeType ?? BikeProfile.city,
      ),
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
    _mapController.registerOnTouch((pos) async {
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

  void _showPopupMenu(BuildContext context) async {
    final BikeProfile? result = await showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(
        100,
        80,
        0,
        0,
      ), // Adjust menu position
      items: [
        const PopupMenuItem(value: BikeProfile.city, child: Text("City")),
        const PopupMenuItem(value: BikeProfile.cross, child: Text("Cross")),
        const PopupMenuItem(
          value: BikeProfile.mountain,
          child: Text("Mountain"),
        ),
        const PopupMenuItem(value: BikeProfile.road, child: Text("Road")),
      ],
    );

    if (result != null) {
      setState(() {
        selectedBikeType = result;
      });
    }
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

enum EBikeType { city, cross, mountain, road }
