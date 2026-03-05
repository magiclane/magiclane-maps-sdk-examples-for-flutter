// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Route;

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';

// ignore_for_file: avoid_print

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
      title: 'Search Along Route',
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
  bool _areRoutesBuilt = false;

  // We use the handler to cancel the route calculation.
  TaskHandler? _routingHandler;

  // We use the handler to cancel the navigation.
  TaskHandler? _navigationHandler;

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
        title: const Text(
          "Search Along Route",
          style: TextStyle(color: Colors.white),
        ),
        leading: Row(
          children: [
            if (_areRoutesBuilt)
              IconButton(
                onPressed: _searchAlongRoute,
                icon: const Icon(Icons.search, color: Colors.white),
              ),
          ],
        ),
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
              onPressed: () => _onBuildRouteButtonPressed(),
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

  void _onMapCreated(GemMapController controller) {
    _mapController = controller;
  }

  // Compute & show route.
  Future<void> _onBuildRouteButtonPressed() async {
    // Define the departure.
    final departureLandmark = Landmark.withLatLng(
      latitude: 37.77903,
      longitude: -122.41991,
    );

    // Define the destination.
    final destinationLandmark = Landmark.withLatLng(
      latitude: 37.33619,
      longitude: -121.89058,
    );

    // Define the route preferences.
    final routePreferences = RoutePreferences();
    _showSnackBar(context, message: 'The route is calculating.');

    _routingHandler = RoutingService.calculateRoute(
      [departureLandmark, destinationLandmark],
      routePreferences,
      (err, routes) async {
        // If the route calculation is finished, we don't have a progress listener anymore.
        _routingHandler = null;

        ScaffoldMessenger.of(context).clearSnackBars();

        // If there aren't any errors, we display the routes.
        if (err == GemError.success) {
          // Get the routes collection from map preferences.
          final routesMap = _mapController.preferences.routes;

          // Display the routes on map.
          for (final route in routes) {
            routesMap.add(
              route,
              route == routes.first,
              label: getMapLabel(route),
            );
          }

          _mapController.centerOnRoute(routes.first);
        }

        setState(() {
          _areRoutesBuilt = true;
        });
      },
    );
  }

  // Start simulated navigation.
  void _startSimulation() {
    if (_isSimulationActive) return;
    if (!_areRoutesBuilt) return;

    _mapController.preferences.routes.clearAllButMainRoute();
    final routes = _mapController.preferences.routes;

    if (routes.mainRoute == null) {
      _showSnackBar(context, message: "No main route available");
      return;
    }

    _navigationHandler = NavigationService.startSimulation(
      routes.mainRoute!,
      onNavigationInstruction: (instruction, events) {
        setState(() {
          _isSimulationActive = true;
        });
      },
      onError: (error) {
        // If the navigation has ended or if and error occurred while navigating, remove routes.
        setState(() {
          _isSimulationActive = false;
          _cancelRoute();
        });

        if (error != GemError.cancel) {
          _stopSimulation();
        }
        return;
      },
    );

    // Set the camera to follow position.
    _mapController.startFollowingPosition();

    setState(() {
      _isSimulationActive = true;
    });
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

  // Stop simulated navigation.
  void _stopSimulation() {
    // Cancel the navigation.
    NavigationService.cancelNavigation(_navigationHandler);
    _navigationHandler = null;

    _cancelRoute();

    setState(() {
      _isSimulationActive = false;
      _areRoutesBuilt = false;
    });
  }

  // Search along route.
  void _searchAlongRoute() {
    if (!_areRoutesBuilt) return;

    final routes = _mapController.preferences.routes;

    if (routes.mainRoute == null) {
      _showSnackBar(context, message: "No main route available");
      return;
    }

    _showSnackBar(context, message: 'Searching along route...');

    // Calling the search along route SDK method.
    // (err, results) - is a callback function that gets called when the search is finished.
    // err is an error enum, results is a list of landmarks.
    SearchService.searchAlongRoute(routes.mainRoute!, (err, results) {
      ScaffoldMessenger.of(context).clearSnackBars();

      if (err != GemError.success) {
        print("SearchAlongRoute - no results found");
        _showSnackBar(
          context,
          message: "No results found",
          duration: const Duration(seconds: 2),
        );
        return;
      }

      print("SearchAlongRoute - ${results.length} results:");
      for (final Landmark landmark in results) {
        final landmarkName = landmark.name;
        print("SearchAlongRoute: $landmarkName");
      }

      // Show the results in a popup dialog
      _showSearchResultsDialog(results);
    });
  }

  // Show search results in a popup dialog
  void _showSearchResultsDialog(List<Landmark> results) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.deepPurple[900]),
                    const SizedBox(width: 8),
                    Text(
                      'Places Along Route',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple[900],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${results.length} found',
                        style: TextStyle(
                          color: Colors.deepPurple[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Results list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final landmark = results[index];
                    return _buildLandmarkTile(landmark, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build a tile for each landmark
  Widget _buildLandmarkTile(Landmark landmark, int index) {
    final coordinates = landmark.coordinates;
    final address = landmark.address;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildLandmarkIcon(landmark, index),
        title: Text(
          landmark.name.isNotEmpty ? landmark.name : 'Unknown Place',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.place, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address.format(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.gps_fixed, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${coordinates.latitude.toStringAsFixed(5)}, ${coordinates.longitude.toStringAsFixed(5)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.center_focus_strong, color: Colors.deepPurple[700]),
          onPressed: () {
            Navigator.pop(context);
            _mapController.centerOnCoordinates(coordinates);
          },
        ),
      ),
    );
  }

  // Build icon for landmark from category image
  Widget _buildLandmarkIcon(Landmark landmark, int index) {
    if (landmark.categories.isNotEmpty) {
      final img = landmark.categories.first.img;
      if (img.isValid) {
        final bytes = img.getRenderableImageBytes(size: const ui.Size(48, 48));
        if (bytes != null) {
          return CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: Image.memory(
              bytes,
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) =>
                  _buildDefaultIcon(index),
            ),
          );
        }
      }
    }
    return _buildDefaultIcon(index);
  }

  // Build default numbered icon
  Widget _buildDefaultIcon(int index) {
    return CircleAvatar(
      backgroundColor: Colors.deepPurple[900],
      child: Text(
        '${index + 1}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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

String getMapLabel(Route route) {
  return '${convertDistance(route.getTimeDistance().totalDistanceM)} \n${convertDuration(route.getTimeDistance().totalTimeS)}';
}

// Utility function to convert the meters distance into a suitable format.
String convertDistance(int meters) {
  if (meters >= 1000) {
    double kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(1)} km';
  } else {
    return '${meters.toString()} m';
  }
}

// Utility function to convert the seconds duration into a suitable format.
String convertDuration(int seconds) {
  int hours = seconds ~/ 3600; // Number of whole hours
  int minutes = (seconds % 3600) ~/ 60; // Number of whole minutes

  String hoursText = (hours > 0) ? '$hours h ' : ''; // Hours text
  String minutesText = '$minutes min'; // Minutes text

  return hoursText + minutesText;
}
