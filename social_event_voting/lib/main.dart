// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:magiclane_maps_flutter/navigation.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/routing.dart' hide Route;

import 'package:flutter/material.dart' hide Animation, Route;
import 'package:magiclane_maps_flutter/search.dart';
import 'package:social_event_voting/social_event_panel.dart';

import 'dart:async';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Social Event Voting',
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
  late GemMapController _mapController;

  AlarmService? _alarmService;
  AlarmListener? _alarmListener;

  // The closest alarm and with its associated distance and image
  OverlayItemPosition? _closestOverlayItem;
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
        backgroundColor: Colors.deepPurple[900],
        title: const Text(
          'Social Event Voting',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (_navigationHandler == null)
            IconButton(
              onPressed: _startSimulation,
              icon: Icon(Icons.route, color: Colors.white),
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SocialEventPanel(
                  overlayItem: _closestOverlayItem!.overlayItem,
                  onClose: () {
                    setState(() {
                      _closestOverlayItem = null;
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // The callback for when map is ready to use.
  void _onMapCreated(GemMapController controller) async {
    // Save controller for further usage.
    _mapController = controller;

    _mapController.registerOnTouch((point) {
      _mapController.setCursorScreenPosition(point);
    });

    _registerSocialEventListener();
  }

  Future<void> _onBuildRouteButtonPressed(BuildContext context) async {
    Route? routeWithReport = await _getRouteWithReport();

    if (routeWithReport != null) {
      _mapController.preferences.routes.add(
        routeWithReport,
        true,
        // Do not show intermediate waypoints as they may cover the report displayed on the map
        routeRenderSettings: RouteRenderSettings(
          options: {
            RouteRenderOptions.showTraffic,
            RouteRenderOptions.showHighlights,
          },
        ),
      );
    } else {
      // ignore: use_build_context_synchronously
      _showSnackBar(context, message: "No route available");
    }
  }

  Future<void> _startSimulation() async {
    await _onBuildRouteButtonPressed(context);
    final routes = _mapController.preferences.routes;

    if (routes.mainRoute == null) {
      // ignore: use_build_context_synchronously
      _showSnackBar(context, message: "No main route available");
      return;
    }

    _navigationHandler = NavigationService.startSimulation(
      routes.mainRoute!,
      onNavigationInstruction: (instruction, events) {},
      onDestinationReached: (landmark) => _stopSimulation(),
    );

    _mapController.startFollowingPosition();
  }

  void _stopSimulation() {
    // Cancel the navigation.
    if (_navigationHandler != null) {
      NavigationService.cancelNavigation(_navigationHandler!);
    }

    setState(() {
      _navigationHandler = null;
    });
    _navigationHandler = null;

    _cancelRoute();
  }

  // Method for removing the routes from display,
  void _cancelRoute() {
    // Remove the routes from map.
    _mapController.preferences.routes.clear();
  }

  void _registerSocialEventListener() {
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

    _alarmService!.alarmDistance = 400;
    _alarmService!.monitorWithoutRoute = true;

    // Add social reports id in order to receive desired notifications via alarm listener
    _alarmService!.overlays.add(CommonOverlayId.socialReports.id);

    setState(() {});
  }

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
