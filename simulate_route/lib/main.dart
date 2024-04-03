import 'package:gem_kit/api/gem_progresslistener.dart';
import 'package:gem_kit/routing.dart';

import 'bottom_navigation_panel.dart';
import 'instruction_model.dart';
import 'top_navigation_panel.dart';
import 'utility.dart';

import 'package:gem_kit/api/gem_mapviewpreferences.dart' as gem;
import 'package:gem_kit/api/gem_navigationservice.dart';
import 'package:gem_kit/api/gem_coordinates.dart';
import 'package:gem_kit/api/gem_landmark.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/gem_kit_basic.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/gem_kit_platform_interface.dart';
import 'package:gem_kit/api/gem_routingservice.dart' as gem;
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
  late InstructionModel currentInstruction;

  List<Coordinates> waypoints = [];
  List<gem.Route> shownRoutes = [];
  ProgressListener? routeListener;

  bool haveRoutes = false;
  bool isNavigating = false;

  @override
  void initState() {
    super.initState();
    waypoints.add(Coordinates(latitude: 45.6517672, longitude: 25.6271132));
    waypoints.add(Coordinates(latitude: 44.4379187, longitude: 26.0122374));
  }

  Future<void> onMapCreated(GemMapController controller) async {
    _mapController = controller;
  }

// Custom method for calling calculate route and displaying the results
  _onPressed(List<Coordinates> waypoints, BuildContext context) {
    // Create a landmark list
    final landmarkWaypoints = LandmarkList.create();

    // Create landmarks from coordinates and add them to the list
    for (final wp in waypoints) {
      var landmark = Landmark.create();
      landmark.setCoordinates(Coordinates(latitude: wp.latitude, longitude: wp.longitude));
      landmarkWaypoints.push_back(landmark);
    }

    final routePreferences = RoutePreferences();
    _showSnackBar(context);

    routeListener = gem.RoutingService.calculateRoute(landmarkWaypoints, routePreferences, (err, routes) async {
      ScaffoldMessenger.of(context).clearSnackBars();
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
          // Add labels to the routes
          routesMap.add(route, firstRoute, label: '$totalDistance \n $totalTime');
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
  }

// Method for creating the simulation
  _navigateOnRoute({required gem.Route route, required Function(InstructionModel) onInstructionUpdated}) {
    NavigationService.startSimulation(route, (type, instruction) async {
      if (type != NavigationEventType.navigationInstructionUpdate || instruction == null) {
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
  _startSimulation(gem.Route route) {
    _navigateOnRoute(
        route: route,
        onInstructionUpdated: (instruction) {
          currentInstruction = instruction;
          setState(() {});
        });

    _mapController.startFollowingPosition(
        animation: gem.GemAnimation(duration: 200, type: gem.EAnimation.AnimationLinear));
  }

// Method for removing the routes from display
  _removeRoutes(List<gem.Route> routes) {
    if (routeListener != null) {
      RoutingService.cancelRoute(routeListener!);
    }
    final prefs = _mapController.preferences();
    final routesMap = prefs.routes();

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
  _stopSimulation(List<gem.Route> routes) {
    NavigationService.cancelNavigation();
    _removeRoutes(routes);
  }

  // Method to show message in case calculate route is not finished
  void _showSnackBar(BuildContext context) {
    const snackBar = SnackBar(
      content: Text("The route is calculating."),
      duration: Duration(hours: 1),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Simulate navigation"),
        backgroundColor: Colors.deepPurple[900],
        foregroundColor: Colors.white,
        actions: [
          GestureDetector(
            onTap: () {
              if (shownRoutes.isEmpty) return;
              _startSimulation(shownRoutes[0]);
            },
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
            child: Icon(Icons.stop, size: 40, color: haveRoutes ? Colors.red : Colors.grey),
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
            child: Column(children: [
              NavigationInstructionPanel(
                instruction: currentInstruction,
              ),
              const SizedBox(
                height: 10,
              ),
              GestureDetector(
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
                          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ]),
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
      ]),
      resizeToAvoidBottomInset: false,
    );
  }
}
