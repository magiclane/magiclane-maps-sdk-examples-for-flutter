// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:gem_kit/navigation.dart';
import 'package:gem_kit/routing.dart';

import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart' hide Route;
import 'package:flutter/services.dart';

import 'dart:async';
import 'dart:io';

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
      title: 'GPX Route',
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
  bool _isGpxDataLoaded = false;
  bool _areRoutesBuilt = false;

  // We use the handler to cancel the navigation.
  TaskHandler? _navigationHandler;

  @override
  void initState() {
    _copyGpxToAppDocsDir();
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
        backgroundColor: Colors.deepPurple[900],
        title: const Text("GPX Route", style: TextStyle(color: Colors.white)),
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
              onPressed: _importGPX,
              icon: const Icon(Icons.route, color: Colors.white),
            ),
        ],
      ),
      body: GemMap(
        key: ValueKey("GemMap"),
        onMapCreated: _onMapCreated,
        appAuthorization: projectApiToken,
      ),
    );
  }

  // The callback for when map is ready to use.
  void _onMapCreated(GemMapController controller) {
    // Save controller for further usage.
    _mapController = controller;
  }

  //Copy the recorded_route.gpx file from assets directory to app documents directory
  Future<void> _copyGpxToAppDocsDir() async {
    if (!kIsWeb) {
      final docDirectory = await getApplicationDocumentsDirectory();
      final gpxFile = File('${docDirectory.path}/recorded_route.gpx');
      final imageBytes = await rootBundle.load('assets/recorded_route.gpx');
      final buffer = imageBytes.buffer;
      await gpxFile.writeAsBytes(
        buffer.asUint8List(imageBytes.offsetInBytes, imageBytes.lengthInBytes),
      );
    }
  }

  //Read GPX data from file, then calculate & show the routes on map
  Future<void> _importGPX() async {
    _showSnackBar(context, message: 'The route is calculating.');

    List<Landmark> landmarkList = [];

    if (kIsWeb) {
      final imageBytes = await rootBundle.load('assets/recorded_route.gpx');
      final buffer = imageBytes.buffer;
      final pathData = buffer.asUint8List(
        imageBytes.offsetInBytes,
        imageBytes.lengthInBytes,
      );

      // Process GPX data using your existing method
      final gemPath = Path.create(data: pathData, format: PathFileFormat.gpx);
      landmarkList = gemPath.toLandmarkList();
    } else {
      //Read file from app documents directory
      final docDirectory = await getApplicationDocumentsDirectory();
      final gpxFile = File('${docDirectory.path}/recorded_route.gpx');

      //Return if GPX file is not found
      if (!await gpxFile.exists()) {
        print('GPX file does not exist (${gpxFile.path})');
        return;
      }

      final bytes = await gpxFile.readAsBytes();
      final pathData = Uint8List.fromList(bytes);

      //Get landmarklist containing all GPX points from file.
      final gemPath = Path.create(data: pathData, format: PathFileFormat.gpx);
      landmarkList = gemPath.toLandmarkList();
    }

    print("GPX Landmarklist size: ${landmarkList.length}");

    // Define the route preferences.
    final routePreferences = RoutePreferences(
      transportMode: RouteTransportMode.bicycle,
    );

    // Calling the calculateRoute SDK method.
    // (err, results) - is a callback function that gets called when the route computing is finished.
    // err is an error enum, results is a list of routes.
    RoutingService.calculateRoute(landmarkList, routePreferences, (
      err,
      routes,
    ) {
      ScaffoldMessenger.of(context).clearSnackBars();

      // If there aren't any errors, we display the routes.
      if (err == GemError.success) {
        // Get the routes collection from map preferences.
        final routesMap = _mapController.preferences.routes;

        // Display the routes on map.
        for (final route in routes) {
          // The first route is the main route
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
    });
    _isGpxDataLoaded = true;
  }

  void _startSimulation() {
    if (_isSimulationActive) return;
    if (!_isGpxDataLoaded) return;

    final routes = _mapController.preferences.routes;

    // Start navigation one the main route.
    _navigationHandler = NavigationService.startSimulation(routes.mainRoute, (
      eventType,
      instruction,
    ) {
      // Navigation instruction callback.
    }, speedMultiplier: 2);

    // Set the camera to follow position.
    _mapController.startFollowingPosition();

    setState(() => _isSimulationActive = true);
  }

  void _stopSimulation() {
    // Remove the routes from map.
    _mapController.preferences.routes.clear();

    setState(() => _areRoutesBuilt = false);

    if (_isSimulationActive) {
      // Cancel the navigation.
      NavigationService.cancelNavigation(_navigationHandler!);
      _navigationHandler = null;

      setState(() => _isSimulationActive = false);
    }
  }

  // Method to show message in case calculate route is not finished
  void _showSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(hours: 1),
  }) {
    final snackBar = SnackBar(content: Text(message), duration: duration);

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

// Define an extension for route for calculating the route label which will be displayed on map
extension RouteExtension on Route {
  String getMapLabel() {
    final totalDistance =
        getTimeDistance().unrestrictedDistanceM +
        getTimeDistance().restrictedDistanceM;
    final totalDuration =
        getTimeDistance().unrestrictedTimeS + getTimeDistance().restrictedTimeS;

    return '${_convertDistance(totalDistance)} \n${_convertDuration(totalDuration)}';
  }

  // Utility function to convert the meters distance into a suitable format
  String _convertDistance(int meters) {
    if (meters >= 1000) {
      double kilometers = meters / 1000;
      return '${kilometers.toStringAsFixed(1)} km';
    } else {
      return '${meters.toString()} m';
    }
  }

  // Utility function to convert the seconds duration into a suitable format
  String _convertDuration(int seconds) {
    int hours = seconds ~/ 3600; // Number of whole hours
    int minutes = (seconds % 3600) ~/ 60; // Number of whole minutes

    String hoursText = (hours > 0) ? '$hours h ' : ''; // Hours text
    String minutesText = '$minutes min'; // Minutes text

    return hoursText + minutesText;
  }
}
