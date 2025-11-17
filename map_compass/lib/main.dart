// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';

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
  void dispose() {
    GemKit.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[900],
        title: const Text("Map Compass", style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          GemMap(
            key: ValueKey("GemMap"),
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
                      child: Image.memory(compassImage!, gaplessPlayback: true),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // The callback for when map is ready to use.
  void _onMapCreated(GemMapController controller) {
    mapController = controller;

    // Register the map angle update callback.
    mapController.registerOnMapAngleUpdate(
      (angle) => setState(() => compassAngle = angle),
    );

    setState(() {
      compassImage = _compassImage();
    });
  }

  Uint8List? _compassImage() {
    // We will use the SDK image for compass but any widget can be used to represent the compass.
    final image = SdkSettings.getImageById(
      id: EngineMisc.compassEnableSensorOFF.id,
      size: const Size(100, 100),
    );
    return image;
  }
}
