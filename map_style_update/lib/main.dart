// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

// ignore_for_file: avoid_print

import 'package:magiclane_maps_flutter/content_store.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';

import 'package:flutter/material.dart';
import 'package:map_style_update/styles_page.dart';

import 'dart:async';

import 'package:map_style_update/styles_provider.dart';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');

void main() {
  // Ensuring that all Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  final autoUpdate = AutoUpdateSettings(
    isAutoUpdateForRoadMapEnabled: true,
    isAutoUpdateForViewStyleHighResEnabled: false,
    isAutoUpdateForViewStyleLowResEnabled: false,
    isAutoUpdateForResourcesEnabled: false,
  );

  GemKit.initialize(
    appAuthorization: projectApiToken,
    autoUpdateSettings: autoUpdate,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Map Styles Update',
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

  late StylesProvider stylesProvider;

  @override
  void initState() {
    super.initState();
    stylesProvider = StylesProvider.instance;
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
          'Map Styles Update',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => _onMapButtonTap(context),
            icon: const Icon(Icons.map_outlined, color: Colors.white),
          ),
        ],
      ),
      body: GemMap(key: ValueKey("GemMap"), onMapCreated: _onMapCreated),
    );
  }

  void _onMapCreated(GemMapController controller) async {
    _mapController = controller;
  }

  Future<void> _onMapButtonTap(BuildContext context) async {
    // Initialize the styles provider
    await stylesProvider.init();

    final result = await Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute<ContentStoreItem>(
        builder: (context) => StylesPage(stylesProvider: stylesProvider),
      ),
    );

    if (result != null) {
      // Handle the returned data

      // Wait for the map refresh to complete
      await Future<void>.delayed(Duration(milliseconds: 800));

      // Set selected map style
      _mapController.preferences.setMapStyle(result);
    }
  }
}
