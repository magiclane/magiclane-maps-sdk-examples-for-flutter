// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:gem_kit/navigation.dart';
import 'package:gem_kit/routing.dart';

import 'bottom_navigation_panel.dart';
import 'top_navigation_panel.dart';
import 'tts_engine.dart';
import 'utility.dart';

import 'package:flutter/material.dart' hide Route, Animation;

void main() {
  const projectApiToken = String.fromEnvironment('GEM_TOKEN');

  GemKit.initialize(appAuthorization: projectApiToken);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Human Voices',
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

  late NavigationInstruction currentInstruction;
  late TTSEngine _ttsEngine;

  bool _areRoutesBuilt = false;
  bool _isSimulationActive = false;

  // We use the handler to cancel the route calculation.
  TaskHandler? _routingHandler;

  // We use the handler to cancel the navigation.
  TaskHandler? _navigationHandler;

  @override
  void initState() {
    _ttsEngine = TTSEngine();
    _ttsEngine.initTts();

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
        title: const Text("Human voices", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple[900],
        actions: [
          if (!_isSimulationActive && _areRoutesBuilt)
            IconButton(
              onPressed: _startSimulation,
              icon: const Icon(Icons.play_arrow, color: Colors.white),
            ),
          if (_isSimulationActive)
            IconButton(
              onPressed: _stopSimulation,
              icon: const Icon(
                Icons.stop,
                color: Colors.white,
              ),
            ),
          if (!_areRoutesBuilt)
            IconButton(
              onPressed: () => _onBuildRouteButtonPressed(context),
              icon: const Icon(
                Icons.route,
                color: Colors.white,
              ),
            ),
        ],
      ),
      body: Stack(children: [
        GemMap(
          onMapCreated: _onMapCreated,
        ),
        if (_isSimulationActive)
          Positioned(
            top: 10,
            left: 10,
            child: Column(children: [
              NavigationInstructionPanel(
                instruction: currentInstruction,
              ),
              const SizedBox(
                height: 10,
              ),
              FollowPositionButton(
                onTap: () => _mapController.startFollowingPosition(),
              ),
            ]),
          ),
        if (_isSimulationActive)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 10,
            left: 0,
            child: NavigationBottomPanel(
              remainingDistance: currentInstruction.getFormattedRemainingDistance(),
              remainingDuration: currentInstruction.getFormattedRemainingDuration(),
              eta: currentInstruction.getFormattedETA(),
            ),
          ),
      ]),
      resizeToAvoidBottomInset: false,
    );
  }

  // The callback for when map is ready to use.
  void _onMapCreated(GemMapController controller) {
    // Save controller for further usage.
    _mapController = controller;
  }

  void _onBuildRouteButtonPressed(BuildContext context) {
    // Define the departure
    final departureLandmark = Landmark();
    departureLandmark.coordinates = Coordinates(latitude: 48.87586140402999, longitude: 2.3031139990581493);

    // Define the intermediary point
    final intermediaryPointLandmark = Landmark();
    intermediaryPointLandmark.coordinates = Coordinates(latitude: 48.87422484785287, longitude: 2.2995244508179242);

    // Define the destination.
    final destinationLandmark = Landmark();
    destinationLandmark.coordinates = Coordinates(latitude: 48.873618858675435, longitude: 2.2951312439853533);

    // Define the route preferences.
    final routePreferences = RoutePreferences();
    _showSnackBar(context);

    // Calling the calculateRoute SDK method.
    // (err, results) - is a callback function that gets called when the route computing is finished.
    // err is an error enum, results is a list of routes.
    _routingHandler = RoutingService.calculateRoute(
        [departureLandmark, intermediaryPointLandmark, destinationLandmark], routePreferences, (err, routes) {
      // If the route calculation is finished, we don't have a progress listener anymore.
      _routingHandler = null;

      ScaffoldMessenger.of(context).clearSnackBars();
      // If there is an error, we return from this callback.

      if (err != GemError.success) {
        setState(() {
          _areRoutesBuilt = false;
        });
        return;
      }

      // Get the routes collection from map preferences.
      final routesMap = _mapController.preferences.routes;

      // Select the first route as the main one.
      final mainRoute = routes!.first;

      // Display the routes on map.
      for (final route in routes) {
        routesMap.add(route, route == mainRoute, label: route.getMapLabel());
      }

      // Center the camera on routes.
      _mapController.centerOnRoutes(routes);
    });

    setState(() {
      _areRoutesBuilt = true;
    });
  }

  void _startSimulation() {
    // Get the main route from map routes collection;
    final routes = _mapController.preferences.routes;
    final mainRoute = routes.mainRoute;

    _navigationHandler = NavigationService.startSimulation(mainRoute, (type, instruction) async {
      if (type == NavigationEventType.destinationReached || type == NavigationEventType.error) {
        // If the navigation has ended or if and error occured while navigating, remove routes.
        setState(() {
          _isSimulationActive = false;
          _cancelRoute();
        });
        return;
      }
      _isSimulationActive = true;

      if (instruction == null) {
        return;
      }

      setState(() => currentInstruction = instruction);
    }, onTextToSpeechInstruction: (textInstruction) {
      // Play the text instruction;
      _ttsEngine.speakText(textInstruction);
    }, speedMultiplier: 20);

    // Set the camera to follow position.
    _mapController.startFollowingPosition();
  }

  void _cancelRoute() {
    // Remove the routes from map.
    _mapController.preferences.routes.clear();

    if (_routingHandler != null) {
      // Cancel the navigation.
      RoutingService.cancelRoute(_routingHandler!);
      _routingHandler = null;
    }

    setState(() {
      _areRoutesBuilt = false;
    });
  }

  void _stopSimulation() {
    // Cancel the navigation.
    NavigationService.cancelNavigation(_navigationHandler!);
    _navigationHandler = null;

    _cancelRoute();

    setState(() => _isSimulationActive = false);
  }

  // Method to show message in case calculate route is not finished
  void _showSnackBar(BuildContext context) {
    const snackBar = SnackBar(
      content: Text("The route is calculating."),
      duration: Duration(hours: 1),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

class FollowPositionButton extends StatelessWidget {
  const FollowPositionButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.navigation),
            Text(
              'Recenter',
              style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
            )
          ],
        ),
      ),
    );
  }
}
