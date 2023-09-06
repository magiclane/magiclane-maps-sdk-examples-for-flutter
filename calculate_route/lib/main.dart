import 'package:gem_kit/gem_kit_basic.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/api/gem_coordinates.dart';
import 'package:gem_kit/api/gem_landmark.dart';
import 'package:gem_kit/api/gem_routingpreferences.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/api/gem_routingservice.dart' as gem;
import 'package:gem_kit/widget/gem_kit_map.dart';
import 'package:flutter/material.dart';

void main() {
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
  late SdkSettings _sdkSettings;
  late gem.RoutingService _routingService;
  List<Coordinates> waypoints = [];
  List<gem.Route> shownRoutes = [];

  bool haveRoutes = false;

  final _token = "YOUR_API_KEY";

  @override
  void initState() {
    super.initState();
    waypoints.add(
        Coordinates(latitude: 48.85682120481962, longitude: 2.343751354197309));
    waypoints.add(Coordinates(
        latitude: 50.846442672966944, longitude: 4.345870353765759));
  }

  Future<void> onMapCreated(GemMapController controller) async {
    _mapController = controller;
    SdkSettings.setAppAuthorization(_token);

    _routingService = await gem.RoutingService.create(_mapController.mapId);
  }

// Custom method for calling calculate route and creating
  _onPressed(List<Coordinates> waypoints, BuildContext context) async {
    // Create a landmark list
    final landmarkWaypoints =
        await gem.LandmarkList.create(_mapController.mapId);

    // Create landmarks from coordinates and add them to the list
    for (final wp in waypoints) {
      var landmark = Landmark.create();
      await landmark.setCoordinates(
          Coordinates(latitude: wp.latitude, longitude: wp.longitude));
      landmarkWaypoints.push_back(landmark);
    }

    final routePreferences = RoutePreferences();

    var result = await _routingService.calculateRoute(
        landmarkWaypoints, routePreferences, (err, routes) async {
      if (err != GemError.success || routes == null) {
        return;
      } else {
        // Get the controller's preferences
        final mapViewPreferences = await _mapController.preferences();
        // Get the routes from the preferences
        final routesMap = await mapViewPreferences.routes();
        //Get the number of routes
        final routesSize = await routes.size();

        for (int i = 0; i < routesSize; i++) {
          final route = await routes.at(i);
          shownRoutes.add(route);

          final timeDistance = await route.getTimeDistance();

          final totalDistance = convertDistance(
              timeDistance.unrestrictedDistanceM +
                  timeDistance.restrictedDistanceM);

          final totalTime = convertDuration(
              timeDistance.unrestrictedTimeS + timeDistance.restrictedTimeS);
          // Add labels to the routes
          await routesMap.add(route, i == 0,
              label: '$totalDistance \n $totalTime');
        }
        // Select the first route as the main one
        final mainRoute = await routes.at(0);

        await _mapController.centerOnRoute(mainRoute);
      }
    });
    haveRoutes = true;

    setState(() {});
    return result;
  }

  _removeRoutes(List<gem.Route> routes) async {
    final prefs = await _mapController.preferences();
    final routesMap = await prefs.routes();

    for (final route in routes) {
      routesMap.remove(route);
    }
    haveRoutes = false;
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
