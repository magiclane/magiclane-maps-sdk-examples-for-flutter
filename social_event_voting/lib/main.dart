// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/navigation.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:gem_kit/routing.dart';

import 'package:flutter/material.dart' hide Animation;
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

    _mapController.registerTouchCallback((point) {
      _mapController.setCursorScreenPosition(point);
    });

    _registerSocialEventListener();
  }

  Future<void> _onBuildRouteButtonPressed(BuildContext context) async {
    final routeCompleter = Completer<void>();
    // Define the departure and destination landmarks (make sure they a social report exists between departure and destination).
    final departureLandmark = Landmark.withLatLng(
      latitude: 50.82686317226226,
      longitude: 4.354871401198793,
    );
    final destinationLandmark = Landmark.withLatLng(
      latitude: 50.82793899084363,
      longitude: 4.3530904551096405,
    );

    // Define the route preferences.
    final routePreferences = RoutePreferences();
    _showSnackBar(context, message: 'The route is calculating.');

    // Calling the calculateRoute SDK method.
    // (err, results) - is a callback function that gets called when the route computing is finished.
    // err is an error enum, results is a list of routes.
    RoutingService.calculateRoute(
      [departureLandmark, destinationLandmark],
      routePreferences,
      (err, routes) async {
        ScaffoldMessenger.of(context).clearSnackBars();

        if (err == GemError.success) {
          final routesMap = _mapController.preferences.routes;
          for (final route in routes) {
            routesMap.add(route, route == routes.first);
          }
          routeCompleter.complete();
        }
      },
    );
    return routeCompleter.future;
  }

  Future<void> _startSimulation() async {
    await _onBuildRouteButtonPressed(context);
    final routes = _mapController.preferences.routes;

    _mapController.preferences.routes.clearAllButMainRoute();

    if (routes.mainRoute == null) {
      // ignore: use_build_context_synchronously
      _showSnackBar(context, message: "No main route available");
      return;
    }

    _navigationHandler = NavigationService.startSimulation(
      routes.mainRoute!,
      null,
      onNavigationInstruction: (instruction, events) {},
      onError: (error) {
        return;
      },
      onDestinationReached: (landmark) => _stopSimulation(),
    );

    _mapController.startFollowingPosition();
  }

  void _stopSimulation() {
    // Cancel the navigation.
    NavigationService.cancelNavigation(_navigationHandler!);
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

    _alarmService!.alarmDistance = 100;

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
