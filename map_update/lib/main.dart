// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:map_update/update_persistence.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'maps_page.dart';

import 'package:flutter/material.dart';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');

void main() {
  GemKit.initialize(appAuthorization: projectApiToken).then((value) {
    SdkSettings.setAllowConnection(true,
        onWorldwideRoadMapSupportStatusCallback: (status) {
      print("UpdatePersistence: onWorldwideRoadMapSupportStatus $status");
      if (status != Status.upToDate) {
        UpdatePersistence.instance.isOldData = true;
      }
    });
    SdkSettings.appAuthorization = projectApiToken;
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

  bool showButton = true;

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
        key: ValueKey("GemMap"),
        onMapCreated: onMapCreated,
        appAuthorization: projectApiToken,
      ),
      floatingActionButton: showButton
          ? FloatingActionButton(
              onPressed: loadMaps,
              child: const Icon(Icons.file_copy),
            )
          : null,
    );
  }

  // Method to navigate to the Maps Page.
  void _onMapButtonTap(BuildContext context) async {
    if (mapId != null) {
      Navigator.of(context).push(MaterialPageRoute<dynamic>(
        builder: (context) => MapsPage(mapId: mapId!),
      ));
    }
  }

  Future<bool> loadAsset(
      String assetName, String destinationDirectoryPath) async {
    final destinationFilePath = path.join(destinationDirectoryPath, assetName);

    File file = File(destinationFilePath);
    if (await file.exists()) {
      return false;
    }
    await file.create();

    final asset = await rootBundle.load('assets/$assetName');
    final buffer = asset.buffer;
    await file.writeAsBytes(
        buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
        flush: true);
    print("Wrote file ${file.path}");
    return true;
  }

  Future<void> loadMaps() async {
    const cmap = 'AndorraOSM_2021Q1.cmap';
    const worldMap = 'WM_7_406.map';

    final dirPath = await getDirPath();
    final resFilePath = path.joinAll([dirPath.path, "Data", "Res"]);
    final mapsFilePath = path.joinAll([dirPath.path, "Data", "Maps"]);

    await deleteAssets(resFilePath, RegExp(r'WM_\d_\d+\.map'));
    await deleteAssets(mapsFilePath, RegExp(r'.+\.cmap'));

    await loadAsset(cmap, mapsFilePath);
    await loadAsset(worldMap, resFilePath);

    ContentStore.refreshContentStore();

    setState(() {
      showButton = false;
    });
  }

  Future<Directory> getDirPath() async {
    if (Platform.isAndroid) {
      return (await getExternalStorageDirectory())!;
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      throw Exception('Platform not supported');
    }
  }

  Future<void> deleteAssets(String directoryPath, RegExp pattern) async {
    final directory = Directory(directoryPath);

    if (!directory.existsSync()) {
      print(
          '\x1B[31mWARNING: Directory $directoryPath not found. Test might fail.\x1B[0m');
    }

    for (final file in directory.listSync()) {
      final filename = path.basename(file.path);
      if (pattern.hasMatch(filename)) {
        try {
          print('INFO DELETE ASSETS: deleting file ${file.path}');
          file.deleteSync();
        } catch (e) {
          print(
              '\x1B[31mWARNING: Deleting file ${file.path} failed. Test might fail. Reason:\n${e.toString()}\x1B[0m');
        }
      }
    }
  }
}
