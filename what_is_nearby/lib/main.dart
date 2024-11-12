// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:gem_kit/sense.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Animation;
import 'package:what_is_nearby/what_is_nearby_page.dart';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        title: 'What\'s Nearby',
        debugShowCheckedModeBanner: false,
        home: MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late GemMapController _mapController;

  PermissionStatus _locationPermissionStatus = PermissionStatus.denied;
  bool _hasLiveDataSource = false;

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
        title:
            const Text('What\'s Nearby', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
              onPressed: () => _onWhatIsNearbyButtonPressed(context),
              icon: const Icon(
                Icons.question_mark,
                color: Colors.white,
              ))
        ],
      ),
      body: GemMap(
        onMapCreated: _onMapCreated,
        appAuthorization: projectApiToken,
      ),
    );
  }

  // The callback for when map is ready to use.
  void _onMapCreated(GemMapController controller) async {
    // Save controller for further usage.
    _mapController = controller;

    if (kIsWeb) {
      // On web platform permission are handled differently than other platforms.
      // The SDK handles the request of permission for location.
      _locationPermissionStatus = PermissionStatus.granted;
    } else {
      // For Android & iOS platforms, permission_handler package is used to ask for permissions.
      _locationPermissionStatus = await Permission.locationWhenInUse.request();
    }

    if (_locationPermissionStatus == PermissionStatus.granted) {
      // After the permission was granted, we can set the live data source (in most cases the GPS).
      // The data source should be set only once, otherwise we'll get -5 error.
      if (!_hasLiveDataSource) {
        PositionService.instance.setLiveDataSource();
        _hasLiveDataSource = true;
      }

      // Optionally, we can set an animation
      final animation = GemAnimation(type: AnimationType.linear);

      // Calling the start following position SDK method.
      _mapController.startFollowingPosition(animation: animation);
    }
  }

  void _onWhatIsNearbyButtonPressed(BuildContext context) {
    // Get the current position with no altitude
    final currentPosition = PositionService.instance.getPosition()!.coordinates;
    final currentPositionNoAltitude = Coordinates(
        latitude: currentPosition.latitude,
        longitude: currentPosition.longitude,
        altitude: 0.0);

    // Pass the current position
    Navigator.of(context).push(MaterialPageRoute<dynamic>(
      builder: (context) => WhatIsNearbyPage(
        position: currentPositionNoAltitude,
      ),
    ));
  }
}
