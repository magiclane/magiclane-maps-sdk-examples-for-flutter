import 'instruction_model.dart';
import 'route_instructions_page.dart';
import 'utility.dart';

import 'package:gem_kit/api/gem_coordinates.dart';
import 'package:gem_kit/api/gem_landmark.dart';
import 'package:gem_kit/api/gem_progresslistener.dart';
import 'package:gem_kit/api/gem_routingpreferences.dart';
import 'package:gem_kit/api/gem_routingservice.dart' as gem;
import 'package:gem_kit/api/gem_routingservice.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/gem_kit_basic.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/gem_kit_platform_interface.dart';
import 'package:gem_kit/widget/gem_kit_map.dart';

import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const token = 'YOUR_API_TOKEN';
  GemKitPlatform.instance.loadNative().then((value) {
    SdkSettings.setAppAuthorization(token);
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Route Instructions',
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
  ProgressListener? routeListener;
  bool haveRoutes = false;

  Future<List<RouteInstructionModel>>? instructions;
  List<gem.Route> shownRoutes = [];

  List<Coordinates> waypoints = [];

  @override
  void initState() {
    super.initState();

    waypoints.add(Coordinates(latitude: 50.11428, longitude: 8.68133));
    waypoints.add(Coordinates(latitude: 49.0069, longitude: 8.4037));
    waypoints.add(Coordinates(latitude: 48.1351, longitude: 11.5820));
  }

  Future<void> onMapCreated(GemMapController controller) async {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[900],
        actions: [
          IconButton(
            onPressed: () {
              _onRouteCancelButtonPressed();
              setState(() {
                haveRoutes = false;
              });
            },
            icon: Icon(Icons.cancel, color: (haveRoutes == true) ? Colors.white : Colors.grey),
          ),
          IconButton(
            onPressed: () {
              if (!haveRoutes) {
                _computeRoute(waypoints, context);
                setState(() {
                  haveRoutes = true;
                });
              }
            },
            icon: Icon(Icons.route, color: (haveRoutes == false) ? Colors.white : Colors.grey),
          ),
        ],
        leading: Row(
          children: [
            IconButton(
              onPressed: () {
                if (instructions != null) {
                  _onRouteInstructionsButtonPressed();
                }
              },
              icon: Icon(
                Icons.density_medium_sharp,
                color: (haveRoutes == true) ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
        title: const Center(
          child: Text(
            "Route Instructions",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Center(
        child: Stack(
          children: [
            GemMap(
              onMapCreated: onMapCreated,
            ),
          ],
        ),
      ),
    );
  }

  _onRouteCancelButtonPressed() async {
    if (routeListener != null) {
      gem.RoutingService.cancelRoute(routeListener!);
    }
    _removeRoutes(shownRoutes);
    instructions = clearInstructionsFuture();
  }

  Future<List<RouteInstructionModel>> clearInstructionsFuture() async {
    return [];
  }

  _onRouteInstructionsButtonPressed() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => RouteInstructionsPage(instructionList: instructions!)));
  }

  _computeRoute(List<Coordinates> waypoints, BuildContext context) {
    //Create a landmark list
    final landmarkWaypoints = LandmarkList.create();

    //Create landmarks from coordinates and add them to the list
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
          shownRoutes.add(route);

          final timeDistance = route.getTimeDistance();

          final totalDistance = convertDistance(timeDistance.unrestrictedDistanceM + timeDistance.restrictedDistanceM);

          final totalTime = convertDuration(timeDistance.unrestrictedTimeS + timeDistance.restrictedTimeS);
          //Add labels to the routes
          routesMap.add(route, firstRoute, label: '$totalDistance \n $totalTime');
          firstRoute = false;
        }
        // Select the first route as the main one
        final mainRoute = routes.at(0);

        final segments = mainRoute.getSegments();

        _mapController.centerOnRoute(mainRoute);

        instructions = _getInstructionsFromSegments(segments);
      }
    });
  }

  Future<List<RouteInstructionModel>> _getInstructionsFromSegments(RouteSegmentList segments) async {
    List<Future<RouteInstructionModel>> instructionFutures = [];

    //Parse all segments and gather all instructions

    for (final segment in segments) {
      final instructionsList = segment.getInstructions();

      for (final instruction in instructionsList) {
        final instr = RouteInstructionModel.fromGemRouteInstruction(instruction);
        instructionFutures.add(instr);
      }
    }
    List<RouteInstructionModel> instructions = await Future.wait(instructionFutures);
    return instructions;
  }

  _removeRoutes(List<gem.Route> routes) async {
    final prefs = _mapController.preferences();
    final routesMap = prefs.routes();

    for (final route in routes) {
      routesMap.remove(route);
    }
    shownRoutes.clear();
  }
}
