// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:gem_kit/navigation.dart';
import 'package:gem_kit/routing.dart';

import 'bottom_alarm_panel.dart';

import 'package:flutter/material.dart' hide Animation, Route;

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
      title: 'Speed Tts Warning',
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

  bool _areRoutesBuilt = false;
  bool _isSimulationActive = false;

  // We use the progress listener to cancel the route calculation.
  TaskHandler? _routingHandler;

  // We use the progress listener to cancel the navigation.
  TaskHandler? _navigationHandler;
  // ignore: unused_field
  AlarmService? _alarmService;
  AlarmListener? _alarmListener;

  // The current speed
  int? _currentSpeed;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    GemKit.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Speed Tts Warning",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple[900],
        actions: [
          if (!_isSimulationActive && _areRoutesBuilt)
            IconButton(
              onPressed: _startSimulation,
              icon: const Icon(Icons.play_arrow, color: Colors.white),
            ),
          if (_isSimulationActive)
            IconButton(
              onPressed: _stopSimulation,
              icon: const Icon(Icons.stop, color: Colors.white),
            ),
          if (!_areRoutesBuilt)
            IconButton(
              onPressed: () => _onBuildRouteButtonPressed(context),
              icon: const Icon(Icons.route, color: Colors.white),
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
          if (_currentSpeed != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 10,
              left: 0,
              child: BottomSpeedLimitPanel(speed: _currentSpeed!),
            ),
        ],
      ),
      resizeToAvoidBottomInset: false,
    );
  }

  void _onMapCreated(GemMapController controller) {
    _mapController = controller;
  }

  // Custom method for calling calculate route and displaying the results.
  void _onBuildRouteButtonPressed(BuildContext context) {
    // Define the departure.
    final departureLandmark = Landmark.withLatLng(
      latitude: 51.35416637819253,
      longitude: 9.378580176120199,
    );
    // Define the destination.
    final destinationLandmark = Landmark.withLatLng(
      latitude: 51.36704970265849,
      longitude: 9.404698019844462,
    );
    // Define the route preferences.
    final routePreferences = RoutePreferences();
    _showSnackBar(context, message: 'The route is calculating.');

    // Calling the calculateRoute SDK method.
    // (err, results) - is a callback function that gets called when the route computing is finished.
    // err is an error enum, results is a list of routes.
    _routingHandler = RoutingService.calculateRoute(
      [departureLandmark, destinationLandmark],
      routePreferences,
      (err, routes) async {
        // If the route calculation is finished, we don't have a progress listener anymore.
        _routingHandler = null;

        ScaffoldMessenger.of(context).clearSnackBars();

        // If there aren't any errors, we display the routes.
        if (err == GemError.success) {
          // Get the routes collection from map preferences.
          final routesMap = _mapController.preferences.routes;

          // Display the routes on map.
          for (final route in routes) {
            routesMap.add(route, route == routes.first);
          }

          // Center the camera on routes.
          _mapController.centerOnRoutes(routes: routes);
        }
        setState(() {
          _areRoutesBuilt = true;
        });
      },
    );
  }

  // Method for starting the simulation and following the position,
  void _startSimulation() {
    final routes = _mapController.preferences.routes;

    _mapController.preferences.routes.clearAllButMainRoute();

    if (routes.mainRoute == null) {
      _showSnackBar(context, message: "No main route available");
      return;
    }

    _alarmListener = AlarmListener(
      onSpeedLimit: (speed, limit, insideCityArea) {
        final speedLimitConverted = (limit * 3.6).toInt();

        if (_currentSpeed != speedLimitConverted) {
          setState(() {
            _currentSpeed = speedLimitConverted;
          });

          final speedWarning = "Current speed limit: $speedLimitConverted";

          SoundPlayingService.playText(speedWarning);
        }
      },
    );

    // Set the alarms service with the listener
    setState(() {
      _alarmService = AlarmService(_alarmListener!);
    });

    _navigationHandler = NavigationService.startSimulation(
      routes.mainRoute!,
      null,
      onNavigationInstruction: (instruction, events) {
        setState(() {
          _isSimulationActive = true;
        });
      },
      onDestinationReached: (landmark) {
        _stopSimulation();
        _cancelRoute();
      },
      onError: (error) {
        // If the navigation has ended or if and error occurred while navigating, remove routes and reset closest alarm.
        setState(() {
          _isSimulationActive = false;
          _cancelRoute();
        });

        if (error != GemError.cancel) {
          _stopSimulation();
        }
        return;
      },
    );

    // Set the camera to follow position.
    _mapController.startFollowingPosition();
  }

  // Method for removing the routes from display,
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

  // Method to stop the simulation and remove the displayed routes,
  void _stopSimulation() {
    // Cancel the navigation.
    NavigationService.cancelNavigation(_navigationHandler!);
    _navigationHandler = null;

    _cancelRoute();

    setState(() {
      _isSimulationActive = false;
      _currentSpeed = null;
      _alarmService = null;
    });
  }

  // Method to show message in case calculate route is not finished,
  void _showSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(hours: 1),
  }) {
    final snackBar = SnackBar(content: Text(message), duration: duration);

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
