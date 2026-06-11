// SPDX-FileCopyrightText: 2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'dart:math';

import 'package:flutter/material.dart' hide Animation;
import 'package:follow_position_advanced/follow_position_controls_panel.dart';
import 'package:follow_position_advanced/follow_position_info_panel.dart';
import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';
import 'follow_position_controller.dart';

const projectApiToken = String.fromEnvironment('YOUR_API_TOKEN_HERE');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GemKit.initialize(appAuthorization: projectApiToken);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Follow Position Advanced',
      debugShowCheckedModeBanner: false,
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
  final FollowPositionController _controller = FollowPositionController();
  TaskHandler? _routingTask;
  TaskHandler? _simulationTask;
  bool _hasMapRoute = false;
  GemMapController? _mapController;

  @override
  void dispose() {
    _controller.dispose();
    GemKit.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isLandscape =
                constraints.maxWidth > constraints.maxHeight;
            final double sidePanelWidth = min(360, constraints.maxWidth * 0.5);
            final Widget bodyContent = isLandscape
                ? _buildLandscapeLayout(sidePanelWidth)
                : _buildPortraitLayout();

            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.deepPurple[900],
                title: const Text(
                  'Follow Position Advanced',
                  style: TextStyle(color: Colors.white),
                ),
                actions: [
                  if (!_hasMapRoute &&
                      _routingTask == null &&
                      _simulationTask == null)
                    IconButton(
                      icon: const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                      ),
                      onPressed: _calculateAndNavigate,
                    ),
                  if (_hasMapRoute)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: _hasMapRoute
                          ? _cancelRoutingAndNavigation
                          : null,
                    ),
                ],
              ),
              body: Column(children: [Expanded(child: bodyContent)]),
            );
          },
        );
      },
    );
  }

  void _onMapCreated(GemMapController controller) async {
    _mapController = controller;
    _controller.attachMapController(controller);
    await _controller.refreshInfo();
  }

  Widget _buildLandscapeLayout(double sidePanelWidth) {
    return Row(
      children: [
        Expanded(
          child: GemMap(
            key: const ValueKey('GemMap'),
            onMapCreated: _onMapCreated,
            appAuthorization: projectApiToken,
          ),
        ),
        SizedBox(width: sidePanelWidth, child: _buildPanelTabs()),
      ],
    );
  }

  Widget _buildPortraitLayout() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GemMap(
              key: const ValueKey('GemMap'),
              onMapCreated: _onMapCreated,
              appAuthorization: projectApiToken,
            ),
          ),
          Expanded(child: _buildPanelTabs()),
        ],
      ),
    );
  }

  Widget _buildPanelTabs() {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.deepPurple[900],
            child: TabBar(
              tabs: const [
                Tab(text: 'Info'),
                Tab(text: 'Controls'),
              ],
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                FollowPositionInfoPanel(controller: _controller),
                FollowPositionControlsPanel(controller: _controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _cancelRoutingAndNavigation() {
    if (_routingTask != null) {
      RoutingService.cancelRoute(_routingTask!);
      _routingTask = null;
    }

    if (_simulationTask != null) {
      NavigationService.cancelNavigation(_simulationTask!);
      _simulationTask = null;
    }

    _mapController?.preferences.routes.clear();

    setState(() {
      _hasMapRoute = false;
    });
  }

  Future<void> _calculateAndNavigate() async {
    if (_routingTask != null || _simulationTask != null) {
      return;
    }

    final departure = Landmark.withCoordinates(
      Coordinates(latitude: 48.85682, longitude: 2.34375),
    ); // Paris
    final destination = Landmark.withCoordinates(
      Coordinates(latitude: 52.370216, longitude: 4.895168),
    ); // Amsterdam

    final prefs = RoutePreferences(
      transportMode: RouteTransportMode.car,
      routeType: RouteType.fastest,
    );

    setState(() {
      _routingTask = RoutingService.calculateRoute(
        [departure, destination],
        prefs,
        (err, routes) {
          _routingTask = null;
          if (err == GemError.success && routes.isNotEmpty) {
            final route = routes.first;
            _mapController?.preferences.routes.add(route, true);
            _mapController?.centerOnArea(route.geographicArea);
            setState(() {
              _hasMapRoute = true;
            });

            _simulationTask = NavigationService.startSimulation(
              route,
              onNavigationInstruction: (instruction, events) {},
              onDestinationReached: (landmark) {},
              onError: (err) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Simulation error: $err')),
                );
              },
              speedMultiplier: 2,
            );

            if (_simulationTask != null) {
              _mapController?.startFollowingPosition();
            }
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Routing error: $err')));
          }
        },
      );
    });
  }
}
