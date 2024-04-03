import 'package:gem_kit/api/gem_coordinates.dart';
import 'package:gem_kit/api/gem_mapviewpreferences.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/gem_kit_platform_interface.dart';
import 'package:gem_kit/widget/gem_kit_map.dart';

import 'package:flutter/material.dart';

void main() {
  const token = "YOUR_API_TOKEN";
  GemKitPlatform.instance.loadNative().then((value) {
    SdkSettings.setAppAuthorization(token);
  });
  runApp(const CenterCoordinatesApp());
}

class CenterCoordinatesApp extends StatelessWidget {
  const CenterCoordinatesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Center Coordinates',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CenterCoordinatesPage(),
    );
  }
}

class CenterCoordinatesPage extends StatefulWidget {
  const CenterCoordinatesPage({super.key});

  @override
  State<CenterCoordinatesPage> createState() => _CenterCoordinatesPageState();
}

class _CenterCoordinatesPageState extends State<CenterCoordinatesPage> {
  late GemMapController _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[900],
        title: const Text('Center Coordinates', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
              onPressed: _onCenterCoordinatesButtonPressed,
              icon: const Icon(
                Icons.adjust,
                color: Colors.white,
              ))
        ],
      ),
      body: GemMap(
        onMapCreated: _onMapCreatedCallback,
      ),
    );
  }

  // The callback for when map is ready to use
  _onMapCreatedCallback(GemMapController controller) async {
    // Save controller for further usage
    _mapController = controller;
  }

  _onCenterCoordinatesButtonPressed() {
    // Predefined coordinates for Rome, Italy
    final targetCoordinates = Coordinates(latitude: 41.902782, longitude: 12.496366);

    // Create an animation (optional)
    final animation = GemAnimation(type: EAnimation.AnimationLinear);

    // Use the map controller to center on coordinates
    _mapController.centerOnCoordinates(targetCoordinates, animation: animation);
  }
}
