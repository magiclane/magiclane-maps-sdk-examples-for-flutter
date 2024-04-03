import 'package:gem_kit/api/gem_coordinates.dart';
import 'package:gem_kit/api/gem_landmark.dart';
import 'package:gem_kit/api/gem_routingpreferences.dart';
import 'package:gem_kit/api/gem_routingservice.dart' as gem;
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/gem_kit_basic.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/gem_kit_platform_interface.dart';
import 'package:gem_kit/widget/gem_kit_map.dart';

import 'package:flutter/material.dart';

void main() {
  const token = "YOUR_API_TOKEN";
  GemKitPlatform.instance.loadNative().then((value) {
    SdkSettings.setAppAuthorization(token);
  });
  runApp(const MultiviewMapApp());
}

class MultiviewMapApp extends StatelessWidget {
  const MultiviewMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Multi Map Routing',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MultiviewMapPage());
  }
}

class MultiviewMapPage extends StatefulWidget {
  const MultiviewMapPage({super.key});

  @override
  State<MultiviewMapPage> createState() => _MultiviewMapPageState();
}

class _MultiviewMapPageState extends State<MultiviewMapPage> {
  late GemMapController _mapController1;
  late GemMapController _mapController2;

  final List<Coordinates> _waypoints1 = [
    Coordinates(latitude: 37.77903, longitude: -122.41991),
    Coordinates(latitude: 37.33619, longitude: -121.89058)
  ];

  final List<Coordinates> _waypoints2 = [
    Coordinates(latitude: 51.50732, longitude: -0.12765),
    Coordinates(latitude: 51.27483, longitude: 0.52316)
  ];

  List<gem.Route> _shownRoutes1 = [];
  List<gem.Route> _shownRoutes2 = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[900],
        title: const Text('Multi Map Routing', style: TextStyle(color: Colors.white)),
        leading: IconButton(
            onPressed: removeRoutes,
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            )),
        actions: [
          IconButton(
              onPressed: route1ButtonAction,
              icon: const Icon(
                Icons.route,
                color: Colors.white,
              )),
          IconButton(
              onPressed: route2ButtonAction,
              icon: const Icon(
                Icons.route,
                color: Colors.white,
              ))
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height / 2 - 50,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GemMap(
                onMapCreated: onMap1Created,
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height / 2 - 50,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GemMap(
                onMapCreated: onMap2Created,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> onMap1Created(GemMapController controller) async {
    _mapController1 = controller;
  }

  Future<void> onMap2Created(GemMapController controller) async {
    _mapController2 = controller;
  }

  Future<void> route1ButtonAction() async {
    final landmarkWaypoints = LandmarkList.create();

    // Create landmarks from coordinates and add them to the list
    for (final wp in _waypoints1) {
      var landmark = Landmark.create();
      landmark.setCoordinates(Coordinates(latitude: wp.latitude, longitude: wp.longitude));
      landmarkWaypoints.push_back(landmark);
    }

    final routePreferences = RoutePreferences();

    gem.RoutingService.calculateRoute(landmarkWaypoints, routePreferences, (err, routes) async {
      if (err != GemError.success || routes == null) {
        return;
      } else {
        // Get the controller's preferences
        final mapViewPreferences = _mapController1.preferences();
        // Get the routes from the preferences
        final routesMap = mapViewPreferences.routes();

        bool firstRoute = true;

        for (final route in routes) {
          _shownRoutes1.add(route);

          final timeDistance = route.getTimeDistance();

          final totalDistance = convertDistance(timeDistance.unrestrictedDistanceM + timeDistance.restrictedDistanceM);

          final totalTime = convertDuration(timeDistance.unrestrictedTimeS + timeDistance.restrictedTimeS);
          // Add labels to the routes
          routesMap.add(route, firstRoute, label: '$totalDistance \n $totalTime');
          firstRoute = false;
        }
        // Select the first route as the main one
        final mainRoute = routes.at(0);

        _mapController1.centerOnRoute(mainRoute);
      }
    });
  }

  Future<void> route2ButtonAction() async {
    final landmarkWaypoints = LandmarkList.create();

    // Create landmarks from coordinates and add them to the list
    for (final wp in _waypoints2) {
      var landmark = Landmark.create();
      landmark.setCoordinates(Coordinates(latitude: wp.latitude, longitude: wp.longitude));
      landmarkWaypoints.push_back(landmark);
    }

    final routePreferences = RoutePreferences();

    gem.RoutingService.calculateRoute(landmarkWaypoints, routePreferences, (err, routes) async {
      if (err != GemError.success || routes == null) {
        return;
      } else {
        // Get the controller's preferences
        final mapViewPreferences = _mapController2.preferences();
        // Get the routes from the preferences
        final routesMap = mapViewPreferences.routes();

        bool firstRoute = false;

        for (final route in routes) {
          _shownRoutes2.add(route);

          final timeDistance = route.getTimeDistance();

          final totalDistance = convertDistance(timeDistance.unrestrictedDistanceM + timeDistance.restrictedDistanceM);

          final totalTime = convertDuration(timeDistance.unrestrictedTimeS + timeDistance.restrictedTimeS);
          // Add labels to the routes
          routesMap.add(route, firstRoute, label: '$totalDistance \n $totalTime');
          firstRoute = false;
        }
        // Select the first route as the main one
        final mainRoute = routes.at(0);

        _mapController2.centerOnRoute(mainRoute);
      }
    });
  }

  Future<void> removeRoutes() async {
    final prefs1 = _mapController1.preferences();
    final routesMap1 = prefs1.routes();
    for (final route in _shownRoutes1) {
      routesMap1.remove(route);
    }
    _shownRoutes1 = [];

    final prefs2 = _mapController2.preferences();
    final routesMap2 = prefs2.routes();
    for (final route in _shownRoutes2) {
      routesMap2.remove(route);
    }
    _shownRoutes2 = [];
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
