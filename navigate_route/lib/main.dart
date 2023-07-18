import 'package:navigate_route/bottom_navigation_panel.dart';
import 'package:navigate_route/instruction_model.dart';
import 'package:navigate_route/position_model.dart';
import 'package:navigate_route/top_navigation_panel.dart';
import 'package:navigate_route/utility.dart';

import 'package:gem_kit/gem_kit_basic.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/gem_kit_position.dart';
import 'package:gem_kit/api/gem_mapviewpreferences.dart' as gem;
import 'package:gem_kit/api/gem_navigationservice.dart';
import 'package:gem_kit/api/gem_coordinates.dart';
import 'package:gem_kit/api/gem_landmark.dart';
import 'package:gem_kit/api/gem_routingpreferences.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/api/gem_routingservice.dart' as gem;
import 'package:gem_kit/widget/gem_kit_map.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Navigate route',
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
  late PositionService _positionService;
  late InstructionModel currentInstruction;
  PermissionStatus locationPermissionStatus = PermissionStatus.denied;

  List<Coordinates> mywaypoints = [];
  List<gem.Route> shownRoutes = [];

  bool haveRoutes = false;
  bool isNavigating = false;
  PositionModel currentPosition = PositionModel(
      latitude: 48.859935072481264,
      longitude: 2.294484386370221,
      altitude: 0,
      speed: 0);

  @override
  void initState() {
    super.initState();
  }

  Future<void> onMapCreated(GemMapController controller) async {
    _mapController = controller;
    SdkSettings.create(_mapController.mapId).then((value) {
      _sdkSettings = value;
      _sdkSettings.setAppAuthorization(
          "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiI0ZTZjNmQxMy0yMTFiLTRhOWQtOGViYS1hMDkxNzg5ZWE2NWEiLCJleHAiOjE4ODE1MjIwMDAsImlzcyI6IkdlbmVyYWwgTWFnaWMiLCJqdGkiOiI4MWZkYTI0Zi1iNTVkLTRiNzEtODViZC02N2QzMGFkNGI4MGQiLCJuYmYiOjE2NjU1NzU0NTZ9.czCmTl26q6uw8XnmMv2KffxVwhNFEN82KJNzeYsRfZJVIa9yXvTPtNl-1BjoxaxWgATANCuqUDQrbdqZlsqj7w");
    });

    _routingService = await gem.RoutingService.create(_mapController.mapId);
    _navigationService = await NavigationService.create(controller.mapId);
    _positionService = await PositionService.create(_mapController.mapId);
  }

// Method for asking for location permission
  _askForLocation() async {
    if (kIsWeb) {
      await _positionService.setLiveDataSource();
      await _positionService.addPositionListener((pos) {
        currentPosition = PositionModel(
            latitude: pos.coordinates.latitude,
            longitude: pos.coordinates.longitude,
            altitude: pos.coordinates.altitude,
            speed: pos.speed);
      });
      setState(() {
        locationPermissionStatus = PermissionStatus.granted;
      });
    } else {
      if (locationPermissionStatus == PermissionStatus.granted) {
        return;
      }
      locationPermissionStatus = await Permission.locationWhenInUse.request();

      if (locationPermissionStatus == PermissionStatus.granted) {
        await _mapController.startFollowingPosition();
        await _positionService.addPositionListener((pos) {
          currentPosition = PositionModel(
              latitude: pos.coordinates.latitude,
              longitude: pos.coordinates.longitude,
              altitude: pos.coordinates.altitude,
              speed: pos.speed);
        });
        setState(() {});
      }
    }
  }

// Method for calling calculate route and displaying the results
  _onPressed(BuildContext context) async {
    mywaypoints.add(Coordinates(
        latitude: currentPosition.latitude,
        longitude: currentPosition.longitude));
    mywaypoints.add(Coordinates(
        latitude: 44.42453081911026, longitude: 26.101618214626367));

    // Create a landmark list
    final landmarkWaypoints =
        await gem.LandmarkList.create(_mapController.mapId);

    // Create landmarks from coordinates and add them to the list
    for (final wp in mywaypoints) {
      var landmark = await Landmark.create(_mapController.mapId);
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

    setState(() {
      haveRoutes = true;
    });
    return result;
  }

// Method for creating the simulation
  _navigateOnRoute(
      {required gem.Route route,
      required Function(InstructionModel) onInstructionUpdated}) async {
    await _navigationService.startNavigation(route, (type, instruction) async {
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
  _startNavigation(gem.Route route) async {
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
    final prefs = await _mapController.preferences();
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
  _stopNavigation(List<gem.Route> routes) async {
    await _navigationService.cancelNavigation();
    _removeRoutes(routes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Navigate route"),
        backgroundColor: Colors.deepPurple[900],
        actions: [
          GestureDetector(
            onTap: () => _startNavigation(shownRoutes[0]),
            child: Icon(Icons.play_arrow,
                size: 40,
                color: haveRoutes
                    ? isNavigating
                        ? Colors.grey
                        : Colors.green
                    : Colors.grey),
          ),
          GestureDetector(
            onTap: () => _stopNavigation(shownRoutes),
            child: Icon(Icons.stop,
                size: 40, color: haveRoutes ? Colors.red : Colors.grey),
          ),
          GestureDetector(
            onTap: () => haveRoutes ? null : _onPressed(context),
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
      floatingActionButtonLocation:
          isNavigating ? null : FloatingActionButtonLocation.endFloat,
      floatingActionButton: isNavigating
          ? null
          : locationPermissionStatus != PermissionStatus.granted
              ? FloatingActionButton(
                  backgroundColor: Colors.white,
                  onPressed: () => _askForLocation(),
                  child: const Icon(Icons.location_off, color: Colors.red),
                )
              : FloatingActionButton(
                  backgroundColor: Colors.white,
                  onPressed: () => _mapController.startFollowingPosition(),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.green,
                  ),
                ),
    );
  }
}
