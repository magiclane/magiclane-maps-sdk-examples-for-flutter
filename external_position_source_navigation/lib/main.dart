// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

// ignore_for_file: avoid_print

import 'dart:math';

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:gem_kit/navigation.dart';
import 'package:gem_kit/routing.dart';
import 'package:gem_kit/sense.dart';

import 'bottom_navigation_panel.dart';
import 'top_navigation_panel.dart';
import 'utility.dart';

import 'package:flutter/material.dart' hide Route, Animation;

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
      title: 'External Position Source Navigation',
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

  late NavigationInstruction currentInstruction;
  late DataSource _dataSource;

  bool _areRoutesBuilt = false;
  bool _isNavigationActive = false;

  bool _hasDataSource = false;

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
        title: const Text(
          "ExternalPositionNavigation",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple[900],
        actions: [
          if (!_isNavigationActive && _areRoutesBuilt)
            IconButton(
              onPressed: () => _startNavigation(),
              icon: const Icon(Icons.play_arrow, color: Colors.white),
            ),
          if (_isNavigationActive)
            IconButton(
              onPressed: _stopNavigation,
              icon: const Icon(Icons.stop, color: Colors.white),
            ),
          if (!_areRoutesBuilt && _hasDataSource)
            IconButton(
              onPressed: () => _onBuildRouteButtonPressed(context),
              icon: const Icon(Icons.route, color: Colors.white),
            ),
          if (!_isNavigationActive)
            IconButton(
              onPressed: _onFollowPositionButtonPressed,
              icon: const Icon(
                Icons.location_searching_sharp,
                color: Colors.white,
              ),
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
          if (_isNavigationActive)
            Positioned(
              top: 10,
              left: 10,
              child: Column(
                children: [
                  NavigationInstructionPanel(instruction: currentInstruction),
                  const SizedBox(height: 10),
                  FollowPositionButton(
                    onTap: () => _mapController.startFollowingPosition(),
                  ),
                ],
              ),
            ),
          if (_isNavigationActive)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 10,
              left: 0,
              child: NavigationBottomPanel(
                remainingDistance:
                    currentInstruction.getFormattedRemainingDistance(),
                remainingDuration:
                    currentInstruction.getFormattedRemainingDuration(),
                eta: currentInstruction.getFormattedETA(),
              ),
            ),
        ],
      ),
      resizeToAvoidBottomInset: false,
    );
  }

  // The callback for when map is ready to use.
  void _onMapCreated(GemMapController controller) {
    // Save controller for further usage.
    _mapController = controller;

    _dataSource = DataSource.createExternalDataSource([DataType.position])!;
  }

  void _onBuildRouteButtonPressed(BuildContext context) {
    // Define the departure
    final departureLandmark = Landmark.withLatLng(
      latitude: 34.915646,
      longitude: -110.147933,
    );

    // Define the destination.
    final destinationLandmark = Landmark.withLatLng(
      latitude: 34.933105,
      longitude: -110.131363,
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
      (err, routes) {
        // If the route calculation is finished, we don't have a progress listener anymore.
        _routingHandler = null;

        ScaffoldMessenger.of(context).clearSnackBars();

        if (err == GemError.routeTooLong) {
          print(
            'The destination is too far from your current location. Change the coordinates of the destination.',
          );
          return;
        }

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
            _areRoutesBuilt = true;
          });
        }
      },
    );
  }

  Future<void> _startNavigation() async {
    final routes = _mapController.preferences.routes;

    if (routes.mainRoute == null) {
      _showSnackBar(context, message: "Route is not available");
      return;
    }

    _navigationHandler = NavigationService.startNavigation(
      routes.mainRoute!,
      null,
      onNavigationInstruction: (instruction, events) {
        setState(() {
          _isNavigationActive = true;
        });
        currentInstruction = instruction;
      },
      onError: (error) {
        PositionService.instance.removeDataSource();
        _dataSource.stop();
        setState(() {
          _isNavigationActive = false;

          _cancelRoute();
        });
        if (error != GemError.cancel) {
          _stopNavigation();
        }
        return;
      },
      onDestinationReached: (landmark) {
        PositionService.instance.removeDataSource();
        _dataSource.stop();
        setState(() {
          _isNavigationActive = false;

          _cancelRoute();
        });
        _stopNavigation();
        return;
      },
    );
    // Set the camera to follow position.
    _mapController.startFollowingPosition();

    // Call method to add external positions
    await _pushExternalPosition();
  }

  Future<void> _pushExternalPosition() async {
    final route = _mapController.preferences.routes.mainRoute;
    final distance = route!.getTimeDistance().totalDistanceM;
    Coordinates prevCoordinates = route.getCoordinateOnRoute(0);

    // Parse route distance
    for (
      int currentDistance = 1;
      currentDistance <= distance;
      currentDistance += 1
    ) {
      if (!_hasDataSource) return;

      // Stop navigation if distance has been parsed
      if (currentDistance == distance) {
        _stopNavigation();
        return;
      }

      // Get coordinate at current distance
      final currentCoordinates = route.getCoordinateOnRoute(currentDistance);

      await Future<void>.delayed(Duration(milliseconds: 25));

      // Add each coordinate from route to data source immediately
      _dataSource.pushData(
        SenseDataFactory.positionFromExternalData(
          ExternalPositionData(
            timestamp: DateTime.now().toUtc().millisecondsSinceEpoch,
            latitude: currentCoordinates.latitude,
            longitude: currentCoordinates.longitude,
            altitude: 0,
            heading: _getHeading(prevCoordinates, currentCoordinates),
            speed: 0,
          ),
        ),
      );
      prevCoordinates = currentCoordinates;
    }
  }

  void _cancelRoute() {
    // Remove the routes from map.
    _mapController.preferences.routes.clear();

    if (_routingHandler != null) {
      // Cancel the calculation of the route.
      RoutingService.cancelRoute(_routingHandler!);
      _routingHandler = null;
    }

    setState(() {
      _areRoutesBuilt = false;
    });
  }

  void _stopNavigation() {
    // Cancel the navigation.
    NavigationService.cancelNavigation(_navigationHandler!);
    _navigationHandler = null;

    PositionService.instance.removeDataSource();
    _dataSource.stop();

    _cancelRoute();

    setState(() {
      _isNavigationActive = false;
      _hasDataSource = false;
    });
  }

  void _onFollowPositionButtonPressed() {
    if (!_hasDataSource) {
      PositionService.instance.setExternalDataSource(_dataSource)!;

      _dataSource.start();

      _dataSource.pushData(
        SenseDataFactory.positionFromExternalData(
          ExternalPositionData(
            timestamp: DateTime.now().toUtc().millisecondsSinceEpoch,
            latitude: 38.029467,
            longitude: -117.884985,
            altitude: 0,
            heading: 0,
            speed: 0,
          ),
        ),
      );
      setState(() {
        _hasDataSource = true;
      });
    }

    final animation = GemAnimation(type: AnimationType.linear);

    _mapController.startFollowingPosition(animation: animation);

    setState(() {});
  }

  // Method to show message in case calculate route is not finished or if current location is not available.
  void _showSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(hours: 1),
  }) {
    final snackBar = SnackBar(content: Text(message), duration: duration);

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Method to calculate position tracker heading
  double _getHeading(Coordinates from, Coordinates to) {
    final dx = to.longitude - from.longitude;
    final dy = to.latitude - from.latitude;

    final val = atan2(dx, dy) * 57.2957795;
    if (val < 0) val + 360;

    return val;
  }
}

class FollowPositionButton extends StatelessWidget {
  const FollowPositionButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.navigation),
            Text(
              'Recenter',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
