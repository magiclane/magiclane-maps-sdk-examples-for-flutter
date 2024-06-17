// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

// ignore_for_file: avoid_print

import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'package:flutter/material.dart';

import 'dart:async';

Future<void> main() async {
  const projectApiToken = String.fromEnvironment('GEM_TOKEN');

  await GemKit.initialize(appAuthorization: projectApiToken);

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

  final _stylesList = <ContentStoreItem>[];
  int _indexOfCurrentStyle = 0;
  bool _isDownloadingStyle = false;

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
          'Map Styles',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (_isDownloadingStyle == true)
            const SizedBox(
              width: 20,
              height: 20,
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
          IconButton(
              onPressed: () => _onMapButtonTap(context),
              icon: const Icon(Icons.map_outlined, color: Colors.white))
        ],
      ),
      body: GemMap(onMapCreated: _onMapCreated),
    );
  }

  void _onMapCreated(GemMapController controller) async {
    _mapController = controller;
    SdkSettings.setAllowOffboardServiceOnExtraChargedNetwork(
        ServiceGroupType.contentService, true);
    getStyles();
  }

  // Method to load the styles
  void getStyles() {
    ContentStore.asyncGetStoreContentList(ContentType.viewStyleLowRes,
        (err, items, isCached) {
      if (err == GemError.success && items != null) {
        for (final item in items) {
          _stylesList.add(item);
        }
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    });
  }

  // Method to download a style
  Future<bool> _downloadStyle(ContentStoreItem style) async {
    setState(() {
      _isDownloadingStyle = true;
    });
    Completer<bool> completer = Completer<bool>();
    style.asyncDownload((err) {
      if (err != GemError.success) {
        // An error was encountered during download
        completer.complete(false);
        setState(() {
          _isDownloadingStyle = false;
        });
        return;
      }
      // Download was succesful
      completer.complete(true);
      setState(() {
        _isDownloadingStyle = false;
      });
    }, onProgressCallback: (progress) {
      // Gets called everytime download progresses with a value between [0, 100]
      print('progress: $progress');
    }, allowChargedNetworks: true);
    return await completer.future;
  }

  // Method to show message in case the styles are still loading
  void _showSnackBar(BuildContext context,
      {required String message, Duration duration = const Duration(hours: 1)}) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: duration,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Method to change the current style
  Future<void> _onMapButtonTap(BuildContext context) async {
    if (_stylesList.isEmpty) {
      _showSnackBar(context, message: "The map styles are loading.");
      getStyles();
      return;
    }

    final indexOfNextStyle = (_indexOfCurrentStyle >= _stylesList.length - 1)
        ? 0
        : _indexOfCurrentStyle + 1;
    ContentStoreItem currentStyle = _stylesList[indexOfNextStyle];

    if (currentStyle.isCompleted == false) {
      final didDownloadSucessfully = await _downloadStyle(currentStyle);
      if (didDownloadSucessfully == false) return;
    }

    _indexOfCurrentStyle = indexOfNextStyle;

    final String filename = currentStyle.fileName;
    _mapController.preferences.setMapStyleByPath(filename);
    setState(() {});
  }
}
