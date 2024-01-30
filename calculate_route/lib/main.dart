import 'package:gem_kit/api/gem_coordinates.dart';
import 'package:gem_kit/api/gem_landmark.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/api/gem_routingpreferences.dart';
import 'package:gem_kit/api/gem_routingservice.dart' as gem;
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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Build route example',
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
  List<Coordinates> waypoints = [];
  List<gem.Route> shownRoutes = [];

  bool haveRoutes = false;

  @override
  void initState() {
    super.initState();
    waypoints.add(
        Coordinates(latitude: 48.85682120481962, longitude: 2.343751354197309));
    waypoints.add(Coordinates(
        latitude: 50.846442672966944, longitude: 4.345870353765759));
  }

  void onMapCreated(GemMapController controller) {
    _mapController = controller;
  }

// Custom method for calling calculate route and creating
  _onPressed(List<Coordinates> waypoints, BuildContext context) async {
    // Create a landmark list
    final landmarkWaypoints = LandmarkList.create();

    // Create landmarks from coordinates and add them to the list
    for (final wp in waypoints) {
      var landmark = Landmark.create();
      landmark.setCoordinates(
          Coordinates(latitude: wp.latitude, longitude: wp.longitude));
      landmarkWaypoints.push_back(landmark);
    }

    final routePreferences = RoutePreferences();

    var result = gem.RoutingService.calculateRouteffi(
        landmarkWaypoints, routePreferences, (err, routes) async {
      if (err != GemError.success || routes == null) {
        return;
      } else {
        // Get the controller's preferences
        final mapViewPreferences = _mapController.preferences();
        // Get the routes from the preferences
        final routesMap = mapViewPreferences.routes();
        //Get the number of routes
        final routesSize = routes.size();

        bool firstRoute = true;

        for (int i = 0; i < routesSize; i++) {
          final route = routes.at(i);
          shownRoutes.add(route);

          final timeDistance = route.getTimeDistance();

          final totalDistance = convertDistance(
              timeDistance.unrestrictedDistanceM +
                  timeDistance.restrictedDistanceM);

          final totalTime = convertDuration(
              timeDistance.unrestrictedTimeS + timeDistance.restrictedTimeS);
          // Add labels to the routes
          await routesMap.add(route, firstRoute,
              label: '$totalDistance \n $totalTime');
          firstRoute = false;
        }
        // Select the first route as the main one
        final mainRoute = routes.at(0);

        _mapController.centerOnRoute(mainRoute);
      }
    });
    haveRoutes = true;

    setState(() {});
    return result;
  }

  _removeRoutes(List<gem.Route> routes) async {
    final prefs = _mapController.preferences();
    await prefs.routes().clear();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GemMap(
          onMapCreated: onMapCreated,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: haveRoutes
          ? FloatingActionButton(
              backgroundColor: Colors.red,
              onPressed: () => _removeRoutes(shownRoutes),
              child: const Icon(Icons.cancel),
            )
          : FloatingActionButton(
              backgroundColor: Colors.deepPurple[900],
              foregroundColor: Colors.white,
              onPressed: () => _onPressed(waypoints, context),
              child: const Icon(Icons.directions),
            ),
      resizeToAvoidBottomInset: false,
    );
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
}
