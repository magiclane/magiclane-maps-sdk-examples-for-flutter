// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'package:flutter/material.dart';

import 'dart:typed_data';

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
      title: 'Map Compass',
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
  late GemMapController mapController;

  double compassAngle = 0;
  Uint8List? compassImage;

  @override
  void initState() {
    super.initState();
  }

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
          "Map Compass",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          GemMap(
            onMapCreated: _onMapCreated,
            appAuthorization: projectApiToken,
          ),
          if (compassImage != null)
            Positioned(
              right: 12,
              top: 12,
              child: InkWell(
                // Align the map north to up.
                onTap: () => mapController.alignNorthUp(),
                child: Transform.rotate(
                  angle: -compassAngle * (3.141592653589793 / 180),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Image.memory(
                        compassImage!,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  // The callback for when map is ready to use.
  void _onMapCreated(GemMapController controller) {
    mapController = controller;
    // Register the map angle update callback.
    mapController.registerOnMapAngleUpdateCallback(
        (angle) => setState(() => compassAngle = angle));
    setState(() {
      compassImage = _compassImage();
    });
  }

  Uint8List _compassImage() {
    // We will use the SDK image for compass but any widget can be used to represent the compass.
    final image = SdkSettings.getImageById(
        id: EngineMisc.compassEnableSensorOFF.id, size: const Size(100, 100));
    return image;
  }
}
