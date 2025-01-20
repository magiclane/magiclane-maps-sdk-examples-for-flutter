// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'dart:math';

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'search_page.dart';

import 'package:flutter/material.dart';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Search Category',
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
        title: const Text("Search Category",
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () => _onSearchButtonPressed(context),
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ],
      ),
      body: GemMap(
        onMapCreated: _onMapCreated,
        appAuthorization: projectApiToken,
      ),
    );
  }

  void _onMapCreated(GemMapController controller) {
    _mapController = controller;
  }

// Custom method for navigating to search screen
  void _onSearchButtonPressed(BuildContext context) async {
// Taking the coordinates at the center of the screen as reference coordinates for search.
    final x = MediaQuery.of(context).size.width / 2;
    final y = MediaQuery.of(context).size.height / 2;
    final mapCoords =
        _mapController.transformScreenToWgs(Point<int>(x.toInt(), y.toInt()));

// Navigating to search screen. The result will be the selected search result(Landmark)
    final result = await Navigator.of(context).push(MaterialPageRoute<dynamic>(
      builder: (context) => SearchPage(
        controller: _mapController,
        coordinates: mapCoords,
      ),
    ));

    if (result is Landmark) {
      // Activating the highlight
      _mapController.activateHighlight([result],
          renderSettings: HighlightRenderSettings());

      // Centering the map on the desired coordinates
      _mapController.centerOnCoordinates(result.coordinates);
    }
  }
}
