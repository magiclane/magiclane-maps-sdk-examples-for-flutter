// ignore_for_file: avoid_print

import 'package:gem_kit/api/gem_navigationservice.dart';
import 'package:gem_kit/api/gem_progresslistener.dart';
import 'package:gem_kit/api/gem_searchservice.dart';
import 'package:gem_kit/api/gem_coordinates.dart';
import 'package:gem_kit/api/gem_landmark.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/api/gem_routingservice.dart' as gem;
import 'package:gem_kit/gem_kit_platform_interface.dart';
import 'package:gem_kit/gem_kit_basic.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/routing.dart';
import 'package:gem_kit/widget/gem_kit_map.dart';

import 'package:flutter/material.dart';

void main() {
  const token = "YOUR_API_TOKEN";
  GemKitPlatform.instance.loadNative().then((value) {
    SdkSettings.setAppAuthorization(token);
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Search Along Route',
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

  bool _isSimulationActive = false;
  bool _haveRoutes = false;
  ProgressListener? routeListener;

  Future<void> onMapCreated(GemMapController controller) async {
    _mapController = controller;
  }

  // Compute & show route
  Future<void> _computeRoute() async {
    // Create a landmark list
    final landmarkWaypoints = LandmarkList.create();

    // Create landmarks from coordinates and add them to the list
    List<Coordinates> waypoints = [
      Coordinates(latitude: 37.77903, longitude: -122.41991),
      Coordinates(latitude: 37.33619, longitude: -121.89058),
    ];

    for (final wp in waypoints) {
      var landmark = Landmark.create();
      landmark.setCoordinates(Coordinates(latitude: wp.latitude, longitude: wp.longitude));
      landmarkWaypoints.push_back(landmark);
    }

    final routePreferences = RoutePreferences();

    routeListener = gem.RoutingService.calculateRoute(landmarkWaypoints, routePreferences, (err, routes) async {
      if (err != GemError.success || routes == null) {
        return;
      } else {
        // Get the controller's preferences
        final mapViewPreferences = _mapController.preferences();
        // Get the routes from the preferences
        final routesMap = mapViewPreferences.routes();

        bool firstRoute = true;
        for (final route in routes) {
          final timeDistance = route.getTimeDistance();

          final totalDistance = convertDistance(timeDistance.unrestrictedDistanceM + timeDistance.restrictedDistanceM);

          final totalTime = convertDuration(timeDistance.unrestrictedTimeS + timeDistance.restrictedTimeS);
          // Add labels to the routes
          routesMap.add(route, firstRoute, label: '$totalDistance \n $totalTime');
          firstRoute = false;
        }
        // Select the first route as the main one
        final mainRoute = routes.at(0);

        _mapController.centerOnRoute(mainRoute);
      }
    });
    setState(() {
      _haveRoutes = true;
    });
  }

  // Start simulated navigation
  void _startPlayback() {
    if (_isSimulationActive) return;
    if (!_haveRoutes) return;

    final routes = _mapController.preferences().routes();
    final mainRoute = routes.getMainRoute();
    NavigationService.startSimulation(mainRoute, speedMultiplier: 2, (eventType, instruction) {});

    _mapController.startFollowingPosition();

    setState(() {
      _isSimulationActive = true;
    });
  }

  // Stop simulated navigation
  void _stopPlayback() {
    if (routeListener != null) {
      RoutingService.cancelRoute(routeListener!);
    }
    if (_isSimulationActive) {
      NavigationService.cancelNavigation();
    }

    _mapController.preferences().routes().clear();

    setState(() {
      _isSimulationActive = false;
      _haveRoutes = false;
    });
  }

  // Search along route
  void _searchAlongRoute() {
    if (!_haveRoutes) return;

    final routes = _mapController.preferences().routes();
    final mainRoute = routes.getMainRoute();

    SearchService.searchAlongRoute(mainRoute, (err, results) {
      if (err != GemError.success || results == null) {
        print("SearchAlongRoute - no results found");
        return;
      }

      int resultsSize = results.size();
      print("SearchAlongRoute - $resultsSize results:");
      for (final Landmark landmark in results) {
        final landmarkName = landmark.getName();
        print("SearchAlongRoute: $landmarkName");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.deepPurple[900],
        leading: IconButton(
          onPressed: _searchAlongRoute,
          icon: Icon(Icons.search, color: !_haveRoutes ? Colors.grey : Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _startPlayback,
            icon: Icon(Icons.play_arrow,
                size: 40,
                color: _haveRoutes
                    ? _isSimulationActive
                        ? Colors.grey
                        : Colors.green
                    : Colors.grey),
          ),
          IconButton(
            onPressed: _stopPlayback,
            icon: Icon(Icons.stop, size: 40, color: _haveRoutes ? Colors.red : Colors.grey),
          ),
          IconButton(
            onPressed: _computeRoute,
            icon: Icon(
              Icons.directions,
              size: 40,
              color: _haveRoutes ? Colors.grey : Colors.white,
            ),
          ),
        ],
      ),
      body: Center(
        child: GemMap(
          onMapCreated: onMapCreated,
        ),
      ),
    );
  }
}

String convertDistance(int meters) {
  if (meters >= 1000) {
    double kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(1)} km';
  } else {
    return '${meters.toString()} m';
  }
}

String convertDuration(int seconds) {
  int hours = seconds ~/ 3600; // Number of whole hours
  int minutes = (seconds % 3600) ~/ 60; // Number of whole minutes

  String hoursText = (hours > 0) ? '$hours h ' : ''; // Hours text
  String minutesText = '$minutes min'; // Minutes text

  return hoursText + minutesText;
}
