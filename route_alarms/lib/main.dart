// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'dart:async';

import 'package:flutter/material.dart' hide Animation, Route;

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';

import 'bottom_alarm_panel.dart';

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
      title: 'Route Alarms',
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

  TaskHandler? _navigationHandler;
  AlarmService? _alarmService;
  AlarmListener? _alarmListener;

  // The closest alarm and with its associated distance and image
  OverlayItemPosition? _closestOverlayItem;

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
          "Route Alarms",
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
          if (_closestOverlayItem != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 10,
              left: 0,
              child: BottomAlarmPanel(
                remainingDistance: _closestOverlayItem!.distance.toString(),
                image: _closestOverlayItem!.overlayItem.img.isValid
                    ? _closestOverlayItem!.overlayItem.img
                          .getRenderableImageBytes()
                    : null,
              ),
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
    // Define the route preferences.
    _showSnackBar(context, message: 'The route is calculating.');

    _getRouteWithReport().then((route) {
      if (route != null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();

        // Get the routes collection from map preferences.
        final routesMap = _mapController.preferences.routes;

        // Display the route on map.
        routesMap.add(
          route,
          true,
          // Do not show waypoints and instructions to not overlap with report
          routeRenderSettings: RouteRenderSettings(
            options: {
              RouteRenderOptions.showTraffic,
              RouteRenderOptions.showHighlights,
            },
          ),
        );

        // Center the camera on routes.
        _mapController.centerOnRoute(route);
      }
      setState(() {
        _areRoutesBuilt = true;
      });
    });
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
      onOverlayItemAlarmsUpdated: () {
        // The overlay item alarm list containing the overlay items that are to be intercepted
        OverlayItemAlarmsList overlayItemAlarms =
            _alarmService!.overlayItemAlarms;

        // The overlay items and their distance from the reference position
        // Sorted ascending by distance from the current position
        List<OverlayItemPosition> items = overlayItemAlarms.items;

        if (items.isEmpty) {
          return;
        }

        // The closest overlay item and its associated distance
        OverlayItemPosition closestOverlayItem = items.first;

        setState(() {
          _closestOverlayItem = closestOverlayItem;
        });
      },
      // When the overlay item alarms are passed over
      onOverlayItemAlarmsPassedOver: () {
        setState(() {
          _closestOverlayItem = null;
        });
      },
    );

    // Set the alarms service with the listener
    _alarmService = AlarmService(_alarmListener!);

    _alarmService!.alarmDistance = 500;

    // Add the social reports overlay to be tracked by the alarm service
    _alarmService!.overlays.add(CommonOverlayId.socialReports.id);

    _navigationHandler = NavigationService.startSimulation(
      routes.mainRoute!,
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
          _closestOverlayItem = null;
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
    NavigationService.cancelNavigation(_navigationHandler);
    _navigationHandler = null;

    _cancelRoute();

    setState(() => _isSimulationActive = false);
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

// Search a social report on the map
// Used for computing a route containing a social report
Future<Landmark?> _getReportFromMap() async {
  final area = RectangleGeographicArea(
    topLeft: Coordinates.fromLatLong(52.59310690528571, 7.524257524882292),
    bottomRight: Coordinates.fromLatLong(
      48.544623829072655,
      12.815748995947535,
    ),
  );
  Completer<Landmark?> completer = Completer<Landmark?>();

  // Allow to search only for social reports
  final searchPreferences = SearchPreferences(
    searchAddresses: false,
    searchMapPOIs: false,
  );
  searchPreferences.overlays.add(CommonOverlayId.socialReports.id);

  SearchService.searchInArea(
    area,
    Coordinates.fromLatLong(51.02858483954893, 10.29982567727901),
    (err, results) {
      if (err == GemError.success) {
        completer.complete(results.first);
      } else {
        completer.complete(null);
      }
    },
    preferences: searchPreferences,
  );

  return completer.future;
}

// Get a route which contains a social report as an intermediate waypoint
// Used for demo, should not be used in a production application
Future<Route?> _getRouteWithReport() async {
  // Create an initial route with a social report
  // This route will stretch accross Germany, containing a social report as an intermediate waypoint
  // It will be cropped to a few hundred meters around the social report
  final initalStart = Landmark.withCoordinates(
    Coordinates.fromLatLong(51.48345483353617, 6.851883736746337),
  );
  final initalEnd = Landmark.withCoordinates(
    Coordinates.fromLatLong(49.01867442442069, 12.061988113314802),
  );
  final report = await _getReportFromMap();
  if (report == null) {
    return null;
  }

  final initialRoute = await _calculateRoute([initalStart, report, initalEnd]);
  if (initialRoute == null) {
    return null;
  }

  // Crop the route to a few hundred meters around the social report
  final reportDistanceInInitialRoute = initialRoute.getDistanceOnRoute(
    report.coordinates,
    true,
  );
  final newStartCoords = initialRoute.getCoordinateOnRoute(
    reportDistanceInInitialRoute - 600,
  );
  final newEndCoords = initialRoute.getCoordinateOnRoute(
    reportDistanceInInitialRoute + 200,
  );

  final newStart = Landmark.withCoordinates(newStartCoords);
  final newEnd = Landmark.withCoordinates(newEndCoords);

  // Make a route containing both directions as the report can be on the opposite direction
  return await _calculateRoute([newStart, report, newEnd, report, newStart]);
}

Future<Route?> _calculateRoute(List<Landmark> waypoints) async {
  Completer<Route?> croppedRouteCompleter = Completer<Route?>();
  RoutingService.calculateRoute(waypoints, RoutePreferences(), (err, routes) {
    if (err == GemError.success) {
      croppedRouteCompleter.complete(routes.first);
    } else {
      croppedRouteCompleter.complete(null);
    }
  });

  return await croppedRouteCompleter.future;
}
