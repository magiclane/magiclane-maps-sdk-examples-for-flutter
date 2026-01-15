// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:flutter/material.dart' hide Route;
import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';
import 'package:round_trip/utils.dart';

const projectApiToken = String.fromEnvironment("GEM_TOKEN");

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, title: 'Round Trip', home: MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late GemMapController _mapController;
  TaskHandler? _routingHandler;
  bool _areRoutesBuilt = false;

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
        title: const Text('Round Trip', style: TextStyle(color: Colors.white)),
        actions: [
          if (!_areRoutesBuilt && _routingHandler == null)
            IconButton(
              onPressed: () => _onBuildRouteButtonPressed(context),
              icon: const Icon(Icons.route, color: Colors.white),
            ),
          if (_routingHandler != null)
            IconButton(
              onPressed: _onCancelRouteButtonPressed,
              icon: const Icon(Icons.stop, color: Colors.white),
            ),
          if (_areRoutesBuilt)
            IconButton(
              onPressed: _onClearRoutesButtonPressed,
              icon: const Icon(Icons.clear, color: Colors.white),
            ),
        ],
      ),
      body: GemMap(key: const ValueKey("GemMap"), appAuthorization: projectApiToken, onMapCreated: _onMapCreated),
    );
  }

  void _onMapCreated(GemMapController mapController) {
    _mapController = mapController;
    // Map is ready to use
  }

  void _onBuildRouteButtonPressed(BuildContext context) {
    // Define departure landmark in Amsterdam
    final departureLandmark = Landmark.withLatLng(latitude: 52.361947, longitude: 4.864486);

    // Define round trip preferences
    final tripPreferences = RoundTripParameters(range: 5000, rangeType: RangeType.distanceBased);

    // Define route preferences to include round trip parameters
    final routePreferences = RoutePreferences(
      transportMode: RouteTransportMode.bicycle,
      roundTripParameters: tripPreferences,
    );

    _showSnackBar(context, message: 'Calculating round trip route...');

    // Use only the departure landmark to calculate a round trip route
    _routingHandler = RoutingService.calculateRoute([departureLandmark], routePreferences, (err, routes) {
      _routingHandler = null;
      ScaffoldMessenger.of(context).clearSnackBars();

      if (err == GemError.success && routes.isNotEmpty) {
        final routesMap = _mapController.preferences.routes;

        for (final route in routes) {
          routesMap.add(route, route == routes.first, label: getMapLabel(route));
        }

        _mapController.centerOnRoutes(routes: routes);

        setState(() {
          _areRoutesBuilt = true;
        });
      } else {
        _showSnackBar(context, message: 'Failed to calculate route', duration: const Duration(seconds: 3));
      }
    });

    setState(() {});
  }

  void _onClearRoutesButtonPressed() {
    _mapController.preferences.routes.clear();

    setState(() {
      _areRoutesBuilt = false;
    });
  }

  void _onCancelRouteButtonPressed() {
    if (_routingHandler != null) {
      RoutingService.cancelRoute(_routingHandler!);

      setState(() {
        _routingHandler = null;
      });
    }
  }

  void _showSnackBar(BuildContext context, {required String message, Duration duration = const Duration(hours: 1)}) {
    final snackBar = SnackBar(content: Text(message), duration: duration);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
