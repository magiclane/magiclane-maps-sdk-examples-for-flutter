// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

// ignore_for_file: avoid_print

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'package:flutter/material.dart';
import 'package:map_gestures/gesture_panel.dart';

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

  String? _mapGesture;

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
      body: Stack(
        children: [
          GemMap(
            key: ValueKey("GemMap"),
            onMapCreated: _onMapCreated,
            appAuthorization: projectApiToken,
          ),
          if (_mapGesture != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 1,
              child: GesturePanel(gesture: _mapGesture!),
            ),
        ],
      ),
    );
  }

  void _onMapCreated(GemMapController controller) async {
    _mapController = controller;

    _mapController.registerOnMapAngleUpdate((angle) {
      setState(() {
        _mapGesture = 'Rotate gesture';
      });
      print("Gesture: onMapAngleUpdate $angle");
    });

    _mapController.registerOnTouch((point) {
      setState(() {
        _mapGesture = 'Touch Gesture';
      });
      print("Gesture: onTouch $point");
    });

    _mapController.registerOnMove((point1, point2) {
      setState(() {
        _mapGesture = 'Pan Gesture';
      });
      print(
        'Gesture: onMove from (${point1.x} ${point1.y}) to (${point2.x} ${point2.y})',
      );
    });

    _mapController.registerOnLongPress((point) {
      setState(() {
        _mapGesture = 'Long Press Gesture';
      });
      print('Gesture: onLongPress $point');
    });

    _mapController.registerOnDoubleTouch((point) {
      setState(() {
        _mapGesture = 'Double Touch Gesture';
      });
      print('Gesture: onDoubleTouch $point');
    });

    _mapController.registerOnPinch((point1, point2, point3, point4, point5) {
      setState(() {
        _mapGesture = 'Pinch Gesture';
      });
      print(
        'Gesture: onPinch from (${point1.x} ${point1.y}) to (${point2.x} ${point2.y})',
      );
    });

    _mapController.registerOnShove((degrees, point1, point2, point3) {
      setState(() {
        _mapGesture = 'Shove Gesture';
      });
      print(
        'Gesture: onShove with $degrees angle from (${point1.x} ${point1.y}) to (${point2.x} ${point2.y})',
      );
    });

    _mapController.registerOnSwipe((distX, distY, speedMMPerSec) {
      setState(() {
        _mapGesture = 'Swipe Gesture';
      });
      print(
        'Gesture: onSwipe with $distX distance in X and $distY distance in Y at $speedMMPerSec mm/s',
      );
    });

    _mapController.registerOnPinchSwipe((point, zoomSpeed, rotateSpeed) {
      setState(() {
        _mapGesture = 'Pinch Swipe Gesture';
      });
      print(
        'Gesture: onPinchSwipe with zoom speed $zoomSpeed and rotate speed $rotateSpeed',
      );
    });

    _mapController.registerOnTwoTouches((point) {
      setState(() {
        _mapGesture = 'Two Touches Gesture';
      });
      print('Gesture: onTwoTouches $point');
    });

    _mapController.registerOnTouchPinch((point1, point2, point3, point4) {
      setState(() {
        _mapGesture = 'Touch Pinch Gesture';
      });
      print(
        'Gesture: onTouchPinch from (${point1.x} ${point1.y}) to (${point2.x} ${point2.y})',
      );
    });
  }

  void showSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
