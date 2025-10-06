// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

// ignore_for_file: avoid_print

import 'package:flutter/services.dart';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';

import 'maps_page.dart';
import 'maps_provider.dart';

import 'package:flutter/material.dart';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A init is required to create the assets directory structure where the
  // road map files are located. The SDK needs to be released before copying
  // the old map files into the assets directory.
  await GemKit.initialize(appAuthorization: projectApiToken);
  await GemKit.release();

  // Simulate old maps
  // delete all maps, all resources and get some old ones
  // AS A USER YOU NEVER DO THAT
  await loadOldMaps(rootBundle);

  final autoUpdate = AutoUpdateSettings(
    isAutoUpdateForRoadMapEnabled: false,
    isAutoUpdateForViewStyleHighResEnabled: false,
    isAutoUpdateForViewStyleLowResEnabled: false,
    isAutoUpdateForHumanVoiceEnabled: false, // default
    isAutoUpdateForComputerVoiceEnabled: false, // default
    isAutoUpdateForCarModelEnabled: false, // default
    isAutoUpdateForResourcesEnabled: false,
  );

  await GemKit.initialize(
    appAuthorization: projectApiToken,
    autoUpdateSettings: autoUpdate,
  );
  await MapsProvider.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Map Update',
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
  GemMapController? mapController;

  void onMapCreated(GemMapController controller) async {
    mapController = controller;
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
        title: const Text('Map Update', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () => _onMapButtonTap(context),
            icon: const Icon(Icons.map_outlined, color: Colors.white),
          ),
        ],
      ),
      body: GemMap(
        key: ValueKey("GemMap"),
        onMapCreated: onMapCreated,
        appAuthorization: projectApiToken,
      ),
      // body: Container(),
    );
  }

  // Method to navigate to the Maps Page.
  void _onMapButtonTap(BuildContext context) async {
    if (mapController != null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<dynamic>(builder: (context) => MapsPage()));
    }
  }
}
