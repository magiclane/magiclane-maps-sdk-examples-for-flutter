// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

// ignore_for_file: non_constant_identifier_names

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  const projectApiToken = String.fromEnvironment('GEM_TOKEN');

  GemKit.initialize(appAuthorization: projectApiToken);

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
        title: const Text('Perspective Map', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
              onPressed: _onChangePersectiveButtonPressed,
              icon: Icon(
                _isInPerspectiveView ? CupertinoIcons.view_2d : CupertinoIcons.view_3d,
                color: Colors.white,
              ))
        ],
      ),
      body: GemMap(
        onMapCreated: _onMapCreated,
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
      _mapPreferences.tiltAngle = _3dViewAngle;
    } else {
      _mapPreferences.tiltAngle = _2dViewAngle;
    }
  }
}
