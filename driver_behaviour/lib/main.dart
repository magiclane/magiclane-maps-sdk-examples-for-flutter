// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/driver_behaviour.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/sense.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:driver_behaviour/analyses_page.dart';

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
      title: 'Driver Behaviour',
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
  late DriverBehaviour _driverBehaviour;

  DriverBehaviourAnalysis? _recordedAnalysis;

  PermissionStatus _locationPermissionStatus = PermissionStatus.denied;
  bool _hasLiveDataSource = false;
  bool _isAnalizing = false;
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
          'Driver Behaviour',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (_hasLiveDataSource && _isAnalizing == false)
            IconButton(
              onPressed: _onRecordButtonPressed,
              icon: Icon(Icons.radio_button_on, color: Colors.white),
            ),
          if (_isAnalizing)
            IconButton(
              onPressed: _onStopRecordingButtonPressed,
              icon: Icon(Icons.stop_circle, color: Colors.white),
            ),
          IconButton(
            onPressed: _onFollowPositionButtonPressed,
            icon: const Icon(
              Icons.location_searching_sharp,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GemMap(
            key: ValueKey("GemMap"),
            onMapCreated: (controller) => _onMapCreated(controller),
            appAuthorization: projectApiToken,
          ),
          if (_recordedAnalysis != null)
            Positioned(
              bottom: 10.0,
              left: 0.0,
              right: 0.0,
              child: ElevatedButton(
                onPressed: () {
                  final analyses =
                      _driverBehaviour.getAllDriverBehaviourAnalyses();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) {
                        return AnalysesPage(behaviourAnalyses: analyses);
                      },
                    ),
                  );
                },
                child: Text("View Analysis"),
              ),
            ),
        ],
      ),
    );
  }

  // The callback for when map is ready to use.
  void _onMapCreated(GemMapController controller) async {
    // Save controller for further usage.
    _mapController = controller;
  }

  Future<void> _onFollowPositionButtonPressed() async {
    if (kIsWeb) {
      // On web platform permission are handled differently than other platforms.
      // The SDK handles the request of permission for location.
      final locationPermssionWeb =
          await PositionService.requestLocationPermission();
      if (locationPermssionWeb == true) {
        _locationPermissionStatus = PermissionStatus.granted;
      } else {
        _locationPermissionStatus = PermissionStatus.denied;
      }
    } else {
      // For Android & iOS platforms, permission_handler package is used to ask for permissions.
      _locationPermissionStatus = await Permission.locationWhenInUse.request();
    }

    if (_locationPermissionStatus == PermissionStatus.granted) {
      // After the permission was granted, we can set the live data source (in most cases the GPS).
      // The data source should be set only once, otherwise we'll get -5 error.
      if (!_hasLiveDataSource) {
        PositionService.setLiveDataSource();
        _hasLiveDataSource = true;
      }

      // Optionally, we can set an animation
      final animation = GemAnimation(type: AnimationType.linear);

      // Calling the start following position SDK method.
      _mapController.startFollowingPosition(animation: animation);

      setState(() {});
    }
  }

  void _onRecordButtonPressed() {
    // Create a live data source
    final liveDataSource = DataSource.createLiveDataSource();

    if (liveDataSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Creating a data source failed.'),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    // Create a DriverBehaviour instance with live data soruce specifications
    final driverBehaviour = DriverBehaviour(
      dataSource: liveDataSource,
      useMapMatch: true,
    );

    setState(() {
      _isAnalizing = true;
      _driverBehaviour = driverBehaviour;
    });

    // Start recording analysis of driver behaviour
    final err = _driverBehaviour.startAnalysis();

    if (!err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Starting analysis failed.'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _onStopRecordingButtonPressed() {
    // Stop recording analysis of driver behaviour
    final analysis = _driverBehaviour.stopAnalysis();

    setState(() {
      _isAnalizing = false;
      _recordedAnalysis = analysis;
    });
  }
}
