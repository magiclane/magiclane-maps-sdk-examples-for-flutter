// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:gem_kit/routing.dart';

import 'package:flutter/material.dart' hide Route;

import 'dart:async';

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
      title: 'Offline Routing',
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

  bool _areRoutesBuilt = false;

  // We use the handler to cancel the route calculation.
  TaskHandler? _routingHandler;

  bool _isDownloaded = false;
  double _downloadProgress = 0;

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
          'Offline Routing',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // Map is downloading.
          if (_isDownloaded == false && _downloadProgress != 0)
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(right: 10.0),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          // Map is not downloaded.
          if (_isDownloaded == false && _downloadProgress == 0)
            IconButton(
              onPressed: () => _setOfflineMap(),
              icon: const Icon(Icons.download, color: Colors.white),
            ),
          // Routes are not built.
          if (_routingHandler == null &&
              _areRoutesBuilt == false &&
              _isDownloaded == true)
            IconButton(
              onPressed: () => _onBuildRouteButtonPressed(context),
              icon: const Icon(Icons.route, color: Colors.white),
            ),
          // Routes calculating is in progress.
          if (_routingHandler != null)
            IconButton(
              onPressed: () => _onCancelRouteButtonPressed(),
              icon: const Icon(Icons.stop, color: Colors.white),
            ),
          // Routes calculating is finished.
          if (_areRoutesBuilt == true)
            IconButton(
              onPressed: () => _onClearRoutesButtonPressed(),
              icon: const Icon(Icons.clear, color: Colors.white),
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

  void _onMapCreated(GemMapController controller) async {
    // Save controller for further usage.
    _mapController = controller;

    SdkSettings.setAllowOffboardServiceOnExtraChargedNetwork(
      ServiceGroupType.contentService,
      true,
    );
  }

  void _onBuildRouteButtonPressed(BuildContext context) {
    // Define the departure.
    final departureLandmark = Landmark.withLatLng(
      latitude: 42.49720,
      longitude: 1.50498,
    );

    // Define the destination.
    final destinationLandmark = Landmark.withLatLng(
      latitude: 42.51003,
      longitude: 1.53400,
    );

    // Define the route preferences.
    final routePreferences = RoutePreferences();

    _showSnackBar(context, message: "The route is being calculated.");

    // Calling the calculateRoute SDK method.
    // (err, results) - is a callback function that gets called when the route computing is finished.
    // err is an error enum, results is a list of routes.

    _routingHandler = RoutingService.calculateRoute(
      [departureLandmark, destinationLandmark],
      routePreferences,
      (err, routes) {
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

          // Center the camera on routes.
          _mapController.centerOnRoutes(routes: routes);
          setState(() {
            _areRoutesBuilt = true;
          });
        }
      },
    );

    setState(() {});
  }

  void _onClearRoutesButtonPressed() {
    // Remove the routes from map.
    _mapController.preferences.routes.clear();

    setState(() {
      _areRoutesBuilt = false;
    });
  }

  void _onCancelRouteButtonPressed() {
    // If we have a progress listener we cancel the route calculation.
    if (_routingHandler != null) {
      RoutingService.cancelRoute(_routingHandler!);

      setState(() {
        _routingHandler = null;
      });
    }
  }

  // Method to load the maps
  Future<List<ContentStoreItem>> _getMaps() async {
    Completer<List<ContentStoreItem>> mapsList =
        Completer<List<ContentStoreItem>>();

    ContentStore.asyncGetStoreContentList(ContentType.roadMap, (
      err,
      items,
      isCached,
    ) {
      if (err == GemError.success && items != null) {
        mapsList.complete(items);
      }
    });
    return mapsList.future;
  }

  // Check and download Andorra's map if it's not already downloaded on the device.
  void _setOfflineMap() {
    // Method to load the local maps
    final localMaps = ContentStore.getLocalContentList(ContentType.roadMap);

    // Check if map is already downloaded
    if (localMaps.where((map) => map.name == 'Andorra').isNotEmpty) {
      setState(() {
        _isDownloaded = true;
      });

      // Deny internet connection
      SdkSettings.setAllowInternetConnection(false);
      return;
    }

    _getMaps().then((maps) {
      _downloadProgress = maps[4].downloadProgress.toDouble();
      _downloadMap(maps[4]);
    });
  }

  void _downloadMap(ContentStoreItem map) {
    // Download the map.
    map.asyncDownload(
      _onMapDownloadFinished,
      onProgress: _onMapDownloadProgressUpdated,
      allowChargedNetworks: true,
    );
  }

  void _onMapDownloadProgressUpdated(int progress) {
    setState(() => _downloadProgress = progress.toDouble());
  }

  void _onMapDownloadFinished(GemError err) {
    // If there is no error, we change the state
    if (err == GemError.success) {
      // Deny internet connection
      SdkSettings.setAllowInternetConnection(false);

      setState(() => _isDownloaded = true);
    }
  }

  // Show a snackbar indicating that the route calculation is in progress.
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
