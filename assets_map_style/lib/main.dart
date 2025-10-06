// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:flutter/services.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';

import 'package:flutter/material.dart';

import 'dart:async';

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
      title: 'Assets Map Style',
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

  bool _isStyleLoaded = false;

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
          'Assets Map Style',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (!_isStyleLoaded)
            IconButton(
              onPressed: () => _applyStyle(),
              icon: Icon(Icons.map, color: Colors.white),
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

  void _onMapCreated(GemMapController controller) async {
    _mapController = controller;
  }

  // Method to change the current style
  Future<void> _applyStyle() async {
    _showSnackBar(context, message: "The map style is loading.");

    await Future<void>.delayed(Duration(milliseconds: 250));

    final styleData = await _loadStyle();

    _mapController.preferences.setMapStyleByBuffer(
      styleData,
      smoothTransition: true,
    );

    setState(() {
      _isStyleLoaded = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    _mapController.centerOnCoordinates(
      Coordinates(latitude: 45, longitude: 20),
      zoomLevel: 25,
    );
  }

  // Method to load style and return it as bytes
  Future<Uint8List> _loadStyle() async {
    // Load style into memory
    final data = await rootBundle.load('assets/Basic_1_Oldtime-1_21_656.style');

    // Convert it to Uint8List
    final bytes = data.buffer.asUint8List();

    return bytes;
  }

  // Method to show message in case the styles are still loading
  void _showSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(hours: 1),
  }) {
    final snackBar = SnackBar(content: Text(message), duration: duration);

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
