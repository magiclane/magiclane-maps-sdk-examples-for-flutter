// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

// ignore_for_file: non_constant_identifier_names

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'package:flutter/cupertino.dart';
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
      title: 'Map Perspective',
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
  // Map preferences are used to change map perspective
  late MapViewPreferences _mapPreferences;

  late bool _isInPerspectiveView = false;

  // Tilt angle for perspective view
  final double _3dViewAngle = 30;

  // Tilt angle for orthogonal/vertical view
  final double _2dViewAngle = 90;

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
          'Perspective Map',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _onChangePersectiveButtonPressed,
            icon: Icon(
              _isInPerspectiveView
                  ? CupertinoIcons.view_2d
                  : CupertinoIcons.view_3d,
              color: Colors.white,
            ),
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

  // The callback for when map is ready to use
  void _onMapCreated(GemMapController controller) async {
    _mapPreferences = controller.preferences;
  }

  void _onChangePersectiveButtonPressed() async {
    setState(() => _isInPerspectiveView = !_isInPerspectiveView);

    // Based on view type, set the view angle
    if (_isInPerspectiveView) {
      _mapPreferences.buildingsVisibility =
          BuildingsVisibility.threeDimensional;
      _mapPreferences.tiltAngle = _3dViewAngle;
    } else {
      _mapPreferences.buildingsVisibility = BuildingsVisibility.twoDimensional;
      _mapPreferences.tiltAngle = _2dViewAngle;
    }
  }
}
