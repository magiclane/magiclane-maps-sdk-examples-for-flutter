// ignore_for_file: avoid_print

import 'package:gem_kit/api/gem_navigationservice.dart';
import 'package:gem_kit/api/gem_routingpreferences.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/api/gem_routingservice.dart' as gem;
import 'package:gem_kit/api/gem_path.dart' as gp;
import 'package:gem_kit/gem_kit_basic.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/gem_kit_platform_interface.dart';
import 'package:gem_kit/widget/gem_kit_map.dart';

import 'package:path_provider/path_provider.dart' as path;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:async';
import 'dart:io' as io;

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

  bool haveRoutes = false;

  @override
  void initState() {
    super.initState();
    copyGpxToAppDocsDir();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[900],
        title: const Text("GPX Route", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: _startPlayback,
            icon: Icon(Icons.play_arrow,
                size: 40,
                color: haveRoutes
                    ? _isSimulationActive
                        ? Colors.grey
                        : Colors.green
                    : Colors.grey),
          ),
          IconButton(
            onPressed: _stopPlayback,
            icon: Icon(Icons.stop, size: 40, color: haveRoutes ? Colors.red : Colors.grey),
          ),
          IconButton(
            onPressed: _importGPX,
            icon: Icon(
              Icons.directions,
              size: 40,
              color: haveRoutes ? Colors.grey : Colors.white,
            ),
          ),
        ],
      ),
      body: GemMap(
        onMapCreated: onMapCreated,
      ),
    );
  }

  Future<void> onMapCreated(GemMapController controller) async {
    _mapController = controller;
  }

  //Copy the recorded_route.gpx file from assets directory to app documents directory
  Future<void> copyGpxToAppDocsDir() async {
    final docDirectory = await path.getApplicationDocumentsDirectory();
    final gpxFile = io.File('${docDirectory.path}/recorded_route.gpx');
    final imageBytes = await rootBundle.load('assets/recorded_route.gpx');
    final buffer = imageBytes.buffer;
    await gpxFile.writeAsBytes(
      buffer.asUint8List(imageBytes.offsetInBytes, imageBytes.lengthInBytes),
    );
  }

  //Read GPX data from file, then calculate & highlight routes on map
  Future<void> _importGPX() async {
    //Read file from app documents directory
    final docDirectory = await path.getApplicationDocumentsDirectory();
    final gpxFile = io.File('${docDirectory.path}/recorded_route.gpx');

    //Read binary gpx file if found
    late Uint8List pathData;
    if (!await gpxFile.exists()) {
      pathData = Uint8List(0);
      print('GPX file does not exist (${gpxFile.path})');
      return;
    } else {
      final bytes = await gpxFile.readAsBytes();
      pathData = Uint8List.fromList(bytes);
    }

    //Get landmarklist containing all GPX points from file.
    final gemPath = gp.Path.create(data: pathData, format: 0);
    final lmkList = gemPath.toLandmarkList();

    print("GPX Landmarklist size: ${lmkList.size()}");

    //Compute routes containing all GPX points
    gem.RoutingService.calculateRoute(
      lmkList,
      RoutePreferences(transportmode: ERouteTransportMode.RTM_Bicycle),
      (err, result) {
        if (err != GemError.success || result == null) {
          return;
        }

        //Highlight routes on map
        final mapRoutes = _mapController.preferences().routes();
        bool firstRoute = true;

        for (final route in result) {
          _addRouteToMap(route: route, mapRoutes: mapRoutes, isMainRoute: firstRoute);
          firstRoute = false;
        }

        //Center on main route
        _mapController.centerOnRoute(result.at(0));
      },
    );
    _isGpxDataLoaded = true;

    setState(() {
      haveRoutes = true;
    });
  }

  // Start simulated navigation
  void _startPlayback() {
    if (_isSimulationActive) return;
    if (!_isGpxDataLoaded) return;

    final routes = _mapController.preferences().routes();
    final mainRoute = routes.getMainRoute();
    NavigationService.startSimulation(mainRoute, (eventType, instruction) {}, speedMultiplier: 2);

    _mapController.startFollowingPosition();

    setState(() {
      _isSimulationActive = true;
    });
  }

  // Stop simulated navigation
  void _stopPlayback() {
    if (!_isSimulationActive) {
      _mapController.preferences().routes().clear();
      setState(() {
        haveRoutes = false;
      });
      return;
    }

    NavigationService.cancelNavigation();
    _mapController.preferences().routes().clear();

    setState(() {
      _isSimulationActive = false;
      haveRoutes = false;
    });
  }

  // Show route on map with label containing estimated time & distance
  void _addRouteToMap(
      {required gem.Route route, required gem.MapViewRoutesCollection mapRoutes, required bool isMainRoute}) {
    final timeDistance = route.getTimeDistance();

    final totalDistance = timeDistance.restrictedDistanceM + timeDistance.unrestrictedDistanceM;
    final totalTime = timeDistance.restrictedTimeS + timeDistance.unrestrictedTimeS;

    final formattedDistance = convertDistance(totalDistance);
    final formattedTime = convertDuration(totalTime);

    mapRoutes.add(route, isMainRoute, label: '$formattedTime \n $formattedDistance');
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
