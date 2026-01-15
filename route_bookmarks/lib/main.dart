import 'package:flutter/material.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/routing.dart';
import 'route_history_page.dart';

const projectApiToken = String.fromEnvironment("GEM_TOKEN");

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, title: 'Route Bookmarks', home: MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late GemMapController _mapController;
  late RouteBookmarks _routeBookmarks;
  TaskHandler? _routingHandler;
  bool _areRoutesBuilt = false;
  int _currentRouteIndex = 0;

  // Define 3 different route pairs
  final List<Map<String, Map<String, double>>> _routePairs = [
    {
      'departure': {'latitude': 48.85682, 'longitude': 2.34375}, // Paris
      'destination': {'latitude': 50.84644, 'longitude': 4.34587}, // Brussels
    },
    {
      'departure': {'latitude': 51.5074, 'longitude': -0.1278}, // London
      'destination': {'latitude': 52.5200, 'longitude': 13.4050}, // Berlin
    },
    {
      'departure': {'latitude': 41.9028, 'longitude': 12.4964}, // Rome
      'destination': {'latitude': 40.4168, 'longitude': -3.7038}, // Madrid
    },
  ];

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
        title: const Text('Route Bookmarks', style: TextStyle(color: Colors.white)),
        actions: [
          if (_routingHandler == null)
            IconButton(
              onPressed: _onHistoryButtonPressed,
              icon: const Icon(Icons.history, color: Colors.white),
              tooltip: 'Route History',
            ),
          if (!_areRoutesBuilt && _routingHandler == null)
            IconButton(
              onPressed: () => _onBuildRouteButtonPressed(context),
              icon: const Icon(Icons.route, color: Colors.white),
            ),
          if (_routingHandler != null)
            IconButton(
              onPressed: _onCancelRouteButtonPressed,
              icon: const Icon(Icons.stop, color: Colors.white),
            ),
          if (_areRoutesBuilt)
            IconButton(
              onPressed: _onClearRoutesButtonPressed,
              icon: const Icon(Icons.clear, color: Colors.white),
            ),
        ],
      ),
      body: GemMap(appAuthorization: projectApiToken, onMapCreated: _onMapCreated),
    );
  }

  void _onMapCreated(GemMapController mapController) {
    _mapController = mapController;
    _routeBookmarks = RouteBookmarks.create('route_history');
  }

  void _onBuildRouteButtonPressed(BuildContext context) {
    // Get current route pair
    final currentPair = _routePairs[_currentRouteIndex];
    final departure = currentPair['departure']!;
    final destination = currentPair['destination']!;

    final departureLandmark = Landmark.withLatLng(latitude: departure['latitude']!, longitude: departure['longitude']!);
    final destinationLandmark = Landmark.withLatLng(
      latitude: destination['latitude']!,
      longitude: destination['longitude']!,
    );
    final routePreferences = RoutePreferences();

    _showSnackBar(context, message: 'Calculating route ${_currentRouteIndex + 1} of ${_routePairs.length}...');

    _routingHandler = RoutingService.calculateRoute([departureLandmark, destinationLandmark], routePreferences, (
      err,
      routes,
    ) {
      _routingHandler = null;
      ScaffoldMessenger.of(context).clearSnackBars();

      if (err == GemError.success) {
        final routesMap = _mapController.preferences.routes;

        for (final route in routes) {
          routesMap.add(route, route == routes.first);
        }

        _mapController.centerOnRoutes(routes: routes);

        // Save route to bookmarks
        _saveRouteToBookmarks(departureLandmark, destinationLandmark, routePreferences);

        setState(() {
          _areRoutesBuilt = true;
          // Cycle to next route pair for next time
          _currentRouteIndex = (_currentRouteIndex + 1) % _routePairs.length;
        });
      }
    });

    setState(() {});
  }

  void _onClearRoutesButtonPressed() {
    _mapController.preferences.routes.clear();

    setState(() {
      _areRoutesBuilt = false;
      _routingHandler = null;
    });
  }

  void _onCancelRouteButtonPressed() {
    if (_routingHandler != null) {
      RoutingService.cancelRoute(_routingHandler!);

      setState(() {
        _routingHandler = null;
      });
    }
  }

  void _onHistoryButtonPressed() async {
    // Clear existing routes before loading from history
    _mapController.preferences.routes.clear();

    // Reset page state
    setState(() {
      _areRoutesBuilt = false;
      _routingHandler = null;
    });

    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => RouteHistoryPage(routeBookmarks: _routeBookmarks)));

    if (result != null && result is Map<String, dynamic>) {
      final waypoints = result['waypoints'] as List<Landmark>?;
      final preferences = result['preferences'] as RoutePreferences?;

      if (waypoints != null && waypoints.length >= 2 && preferences != null) {
        _calculateRouteFromHistory(waypoints, preferences);
      }
    }
  }

  void _calculateRouteFromHistory(List<Landmark> waypoints, RoutePreferences preferences) {
    _showSnackBar(context, message: 'Calculating route from history...');

    _routingHandler = RoutingService.calculateRoute(waypoints, preferences, (err, routes) {
      _routingHandler = null;
      ScaffoldMessenger.of(context).clearSnackBars();

      if (err == GemError.success) {
        final routesMap = _mapController.preferences.routes;

        for (final route in routes) {
          routesMap.add(route, route == routes.first);
        }

        _mapController.centerOnRoutes(routes: routes);

        setState(() {
          _areRoutesBuilt = true;
        });
      } else {
        _showSnackBar(context, message: 'Failed to calculate route', duration: const Duration(seconds: 3));
      }
    });

    setState(() {});
  }

  void _saveRouteToBookmarks(Landmark departure, Landmark destination, RoutePreferences preferences) {
    final timestamp = DateTime.now();
    final routeName =
        'Route ${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

    _routeBookmarks.add(routeName, [departure, destination], preferences: preferences, overwrite: false);
  }

  void _showSnackBar(BuildContext context, {required String message, Duration duration = const Duration(hours: 1)}) {
    final snackBar = SnackBar(content: Text(message), duration: duration);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
