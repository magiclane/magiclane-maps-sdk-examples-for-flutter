// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'maps_page.dart';

import 'package:flutter/material.dart';

OffBoardListener? offBoardListener;

// In order to test with older map you need to manually modify the app files on the device:
// Put old region .cmap file into \Data\Maps
// Put old VM .map file into \Data\Res
void main() {
  const projectApiToken = String.fromEnvironment('GEM_TOKEN');

  GemKit.initialize(appAuthorization: projectApiToken).then((value) {
    offBoardListener = OffBoardListener(false);
    offBoardListener!.registerOnApiTokenUpdated(() {});

    SdkSettings.setAllowConnection(true, offBoardListener!);
    SdkSettings.setAppAuthorization(projectApiToken);
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Map update',
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
        title: const Text(
          'Map Update',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
              onPressed: () => _onMapButtonTap(context),
              icon: const Icon(
                Icons.map_outlined,
                color: Colors.white,
              ))
        ],
      ),
      body: GemMap(
        onMapCreated: onMapCreated,
      ),
    );
  }

  // Method to navigate to the Maps Page.
  void _onMapButtonTap(BuildContext context) async {
    if (mapId == null) return;
    Navigator.of(context).push(MaterialPageRoute<dynamic>(
      builder: (context) => MapsPage(mapId: mapId!),
    ));
  }
}
