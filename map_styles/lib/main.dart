// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

// ignore_for_file: avoid_print

import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'package:flutter/material.dart';

import 'dart:async';

import 'package:map_styles/map_styles_page.dart';

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
      title: 'Map Styles',
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
        title: const Text('Map Styles', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () async => await _onMapButtonTap(context),
            icon: const Icon(Icons.map_outlined, color: Colors.white),
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

    SdkSettings.setAllowOffboardServiceOnExtraChargedNetwork(
      ServiceGroupType.contentService,
      true,
    );

    _mapController.registerSetMapStyleCallback((styleId, stylePath, viaApi) {
      print("Style updated!");
    });
  }

  Future<void> _onMapButtonTap(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute<ContentStoreItem>(
        builder: (context) => MapStylesPage(),
      ),
    );

    if (result != null) {
      // Handle the returned data

      // Wait for the map refresh to complete
      await Future<void>.delayed(Duration(milliseconds: 500));

      // Set selected map style
      _mapController.preferences.setMapStyle(result);
    }
  }
}
