import 'bottom_navigation_panel.dart';
import 'instruction_model.dart';
import 'top_navigation_panel.dart';
import 'tts_engine.dart';
import 'utility.dart';

import 'package:gem_kit/api/gem_coordinates.dart';
import 'package:gem_kit/api/gem_mapviewpreferences.dart' as gem;
import 'package:gem_kit/api/gem_navigationservice.dart';
import 'package:gem_kit/api/gem_landmark.dart';
import 'package:gem_kit/api/gem_routingpreferences.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/api/gem_routingservice.dart' as gem;
import 'package:gem_kit/gem_kit_basic.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/gem_kit_platform_interface.dart';
import 'package:gem_kit/widget/gem_kit_map.dart';

import 'package:flutter/cupertino.dart';
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
      title: 'Human voices example',
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

  late InstructionModel currentInstruction;
  late TTSEngine _ttsEngine;

  List<Coordinates> waypoints = [];
  List<gem.Route> shownRoutes = [];

  bool haveRoutes = false;
  bool isNavigating = false;
  bool hasVolume = true;

  @override
  void initState() {
    super.initState();
    waypoints.add(Coordinates(
        latitude: 48.87586140402999, longitude: 2.3031139990581493));
    waypoints.add(Coordinates(
        latitude: 48.87422484785287, longitude: 2.2995244508179242));
    waypoints.add(Coordinates(
        latitude: 48.873618858675435, longitude: 2.2951312439853533));
  }

  Future<void> onMapCreated(GemMapController controller) async {
    _mapController = controller;

    _ttsEngine = TTSEngine();
    _ttsEngine.initTts();
  }

// Custom method for calling calculate route and displaying the results
  _onPressed(List<Coordinates> waypoints, BuildContext context) {
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

        bool firstRoute = true;
        for (final route in routes) {
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

    setState(() {
      haveRoutes = true;
    });
    return result;
  }

// Method for creating the simulation
  _navigateOnRoute(
      {required gem.Route route,
      required Function(InstructionModel) onInstructionUpdated}) {
    NavigationService.startSimulation(route, (type, instruction) async {
      if (type == NavigationEventType.destinationReached &&
          instruction == null) {
        setState(() {
          isNavigating = false;
          _removeRoutes(shownRoutes);
        });
        return;
      }

      isNavigating = true;

      final ins = await InstructionModel.fromGemInstruction(instruction!);
      onInstructionUpdated(ins);

      instruction.dispose();
    }, onTextToSpeechInstruction: (textToSpeech) {
      _ttsEngine.speakText(textToSpeech);
    });
  }

// Method for starting the simulation and following the position
  _startSimulation(gem.Route route) {
    _navigateOnRoute(
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
  _removeRoutes(List<gem.Route> routes) {
    _mapController.preferences().routes().clear();
    shownRoutes.clear();

    setState(() {
      haveRoutes = false;
    });
  }

// Method to stop the simulation and remove the displayed routes
  _stopSimulation(List<gem.Route> routes) {
    NavigationService.cancelNavigation();
    _removeRoutes(routes);
    isNavigating = false;
    setState(() {});

    hasVolume = true;
  }

// Method to mute / unmute the voice instructions
  _setVolume() {
    double volume = hasVolume ? 0.0 : 1.0;
    _ttsEngine.setVolume(volume);
    hasVolume = !hasVolume;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Human voices", style: TextStyle(color: Colors.white)),
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
            onTap: () {
              _stopSimulation(shownRoutes);
              setState(() {
                isNavigating = false;
              });
            },
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
            top: 20,
            left: 10,
            child: NavigationInstructionPanel(
              instruction: currentInstruction,
            ),
          ),
        if (isNavigating)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            right: 10,
            child: FloatingActionButton.small(
              onPressed: () => _setVolume(),
              backgroundColor: Colors.white,
              child: hasVolume
                  ? const Icon(
                      CupertinoIcons.volume_up,
                      color: Colors.black,
                    )
                  : const Icon(
                      CupertinoIcons.volume_mute,
                      color: Colors.black,
                    ),
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
            top: MediaQuery.of(context).size.height * 0.30,
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
