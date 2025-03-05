// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

// ignore_for_file: avoid_print

import 'package:flutter/services.dart';

import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'asset_bundle_utils.dart';
import 'maps_page.dart';
import 'update_persistence.dart';

import 'package:flutter/material.dart';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');

void main() async {
  // Ensuring that all Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Simulate old maps
  await rootBundle.loadOldMaps();

  GemKit.initialize(appAuthorization: projectApiToken).then((value) {
    ContentStore.refreshContentStore();

    SdkSettings.setAllowConnection(
      true,
      onWorldwideRoadMapSupportStatusCallback: (status) {
        print("UpdatePersistence: onWorldwideRoadMapSupportStatus $status");
        if (status != Status.upToDate) {
          UpdatePersistence.instance.isOldData = true;
        }
      },
    );
  });

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
  int? mapId;

  void onMapCreated(GemMapController controller) async {
    mapId = controller.mapId;
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
    );
  }

  // Method to navigate to the Maps Page.
  void _onMapButtonTap(BuildContext context) async {
    if (mapId != null) {
      Navigator.of(context).push(
        MaterialPageRoute<dynamic>(
          builder: (context) => MapsPage(mapId: mapId!),
        ),
      );
    }
  }
}
