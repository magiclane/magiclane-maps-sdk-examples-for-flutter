import 'package:simulate_route/bottom_navigation_panel.dart';
import 'package:simulate_route/instruction_model.dart';
import 'package:simulate_route/top_navigation_panel.dart';
import 'package:simulate_route/utility.dart';

import 'package:gem_kit/gem_kit_basic.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/api/gem_mapviewpreferences.dart' as gem;
import 'package:gem_kit/api/gem_navigationservice.dart';
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
      title: 'Simulate route ',
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
  late NavigationService _navigationService;
  late InstructionModel currentInstruction;

  List<Coordinates> waypoints = [];
  List<gem.Route> shownRoutes = [];

  bool haveRoutes = false;
  bool isNavigating = false;

  final _token = 'YOUR_API_KEY';

  @override
  void initState() {
    super.initState();
    waypoints.add(Coordinates(
        latitude: 48.87586140402999, longitude: 2.3031139990581493));
    waypoints.add(Coordinates(
        latitude: 48.873618858675435, longitude: 2.2951312439853533));
  }

  Future<void> onMapCreated(GemMapController controller) async {
    _mapController = controller;
    SdkSettings.setAppAuthorization(_token);

    _routingService = await gem.RoutingService.create(_mapController.mapId);
    _navigationService = await NavigationService.create(controller.mapId);
  }

// Custom method for calling calculate route and displaying the results
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
        final mapViewPreferences = _mapController.preferences();
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

    setState(() {
      haveRoutes = true;
    });
    return result;
  }

// Method for creating the simulation
  _navigateOnRoute(
      {required gem.Route route,
      required Function(InstructionModel) onInstructionUpdated}) async {
    await _navigationService.startSimulation(route, (type, instruction) async {
      if (type != NavigationEventType.navigationInstructionUpdate ||
          instruction == null) {
        setState(() {
          isNavigating = false;
          _removeRoutes(shownRoutes);
        });
        return;
      }

      isNavigating = true;

      final ins = await InstructionModel.fromGemInstruction(instruction);
      onInstructionUpdated(ins);

      instruction.dispose();
    });
  }

// Method for starting the simulation and following the position
  _startSimulation(gem.Route route) async {
    await _navigateOnRoute(
        route: route,
        onInstructionUpdated: (instruction) {
          currentInstruction = instruction;
          setState(() {});
        });

    _mapController.startFollowingPosition(
        animation: gem.GemAnimation(
            duration: 200, type: gem.EAnimation.AnimationLinear));
  }

// Method for removing the routes from display
  _removeRoutes(List<gem.Route> routes) async {
    final prefs = _mapController.preferences();
    final routesMap = await prefs.routes();

    for (final route in routes) {
      routesMap.remove(route);
    }

    shownRoutes.clear();
    setState(() {
      haveRoutes = false;
      isNavigating = false;
    });
  }

// Method to stop the simulation and remove the displayed routes
  _stopSimulation(List<gem.Route> routes) async {
    await _navigationService.cancelNavigation();
    _removeRoutes(routes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Simulate navigation"),
        backgroundColor: Colors.deepPurple[900],
        actions: [
          GestureDetector(
            onTap: () => _startSimulation(shownRoutes[0]),
            child: Icon(Icons.play_arrow,
                size: 40,
                color: haveRoutes
                    ? isNavigating
                        ? Colors.grey
                        : Colors.green
                    : Colors.grey),
          ),
          GestureDetector(
            onTap: () => _stopSimulation(shownRoutes),
            child: Icon(Icons.stop,
                size: 40, color: haveRoutes ? Colors.red : Colors.grey),
          ),
          GestureDetector(
            onTap: () => haveRoutes ? null : _onPressed(waypoints, context),
            child: Icon(
              Icons.directions,
              size: 40,
              color: haveRoutes ? Colors.grey : Colors.white,
            ),
          )
        ],
      ),
      body: Stack(children: [
        GemMap(
          onMapCreated: onMapCreated,
        ),
        if (isNavigating)
          Positioned(
            top: 40,
            left: 10,
            child: NavigationInstructionPanel(
              instruction: currentInstruction,
            ),
          ),
        if (isNavigating)
          Positioned(
            bottom: 30,
            left: 0,
            child: NavigationBottomPanel(
              remainingDistance: currentInstruction.remainingDistance,
              eta: currentInstruction.eta,
              remainingDuration: currentInstruction.remainingDuration,
            ),
          ),
        if (isNavigating)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.26,
            left: MediaQuery.of(context).size.width / 2 - 65,
            child: GestureDetector(
              onTap: () => _mapController.startFollowingPosition(),
              child: InkWell(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.navigation,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const Text(
                        'Recenter',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
      ]),
      resizeToAvoidBottomInset: false,
    );
  }
}
