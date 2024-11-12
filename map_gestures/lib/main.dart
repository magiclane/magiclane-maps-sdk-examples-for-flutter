// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

// ignore_for_file: avoid_print

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'package:flutter/material.dart';

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
      title: 'Map Gestures',
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
  // GemMapController object used to interact with the map
  late GemMapController _mapController;

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
          'Map Gestures',
          style: TextStyle(color: Colors.white),
        ),
        actions: [],
      ),
      body: GemMap(
        onMapCreated: _onMapCreated,
        appAuthorization: projectApiToken,
      ),
    );
  }

  void _onMapCreated(GemMapController controller) async {
    _mapController = controller;

    _mapController.registerOnMapAngleUpdate((angle) {
      print("Gesture: onMapAngleUpdate $angle");
    });

    _mapController.registerTouchCallback((point) {
      print("Gesture: onTouch $point");
    });

    _mapController.registerMoveCallback((point1, point2) {
      print(
          'Gesture: onMove from (${point1.x} ${point1.y}) to (${point2.x} ${point2.y})');
    });

    _mapController.registerOnLongPressCallback((point) {
      print('Gesture: onLongPress $point');
    });
  }
}
