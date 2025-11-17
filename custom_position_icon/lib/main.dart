// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Animation;
import 'package:flutter/services.dart' show rootBundle;

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Custom Position Icon',
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
        title: const Text(
          'Custom Position Icon',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _onFollowPositionButtonPressed,
            icon: const Icon(
              Icons.location_searching_sharp,
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

  // The callback for when map is ready to use.
  void _onMapCreated(GemMapController controller) async {
    // Save controller for further usage.
    _mapController = controller;

    // You can upload a custom icon for the position tracker, it can also be a 3D object as "quad.glb" file in the assets, or use a texture.
    //final bytes = await loadAsUint8List('assets/quad.glb');
    final bytes = await loadAsUint8List('assets/navArrow.png');
    setPositionTrackerImage(bytes, scale: 0.5);
  }

  void _onFollowPositionButtonPressed() async {
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

  // Helper function to load an asset as byte array.
  Future<Uint8List> loadAsUint8List(String filename) async {
    final fileData = await rootBundle.load(filename);
    return fileData.buffer.asUint8List();
  }

  // Method that sets the custom icon for the position tracker.
  void setPositionTrackerImage(Uint8List imageData, {double scale = 1.0}) {
    try {
      MapSceneObject.customizeDefPositionTracker(
        imageData,
        SceneObjectFileFormat.tex,
      );
      final positionTracker = MapSceneObject.getDefPositionTracker();

      positionTracker.scale = scale;
    } catch (e) {
      throw (e.toString());
    }
  }
}
