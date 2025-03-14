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
        title: const Text('Map Styles', style: TextStyle(color: Colors.white)),
        actions: [
          if (_isDownloadingStyle)
            const SizedBox(
              width: 20,
              height: 20,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          IconButton(
            onPressed: () => _onMapButtonTap(context),
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
  }

  // Method to load the styles
  void getStyles() {
    _showSnackBar(context, message: "Styles list is loading.");

    ContentStore.asyncGetStoreContentList(ContentType.viewStyleLowRes, (
      err,
      items,
      isCached,
    ) {
      if (err == GemError.success) {
        _stylesList.addAll(items!);

        ScaffoldMessenger.of(context).clearSnackBars();

        _showSnackBar(
          context,
          message: "Styles list is loaded.",
          duration: Duration(seconds: 2),
        );
      } else {
        _showSnackBar(
          context,
          message: "Styles list could not be loaded.",
          duration: Duration(seconds: 2),
        );
      }
    });
  }

  // Method to download a style
  Future<bool> _downloadStyle(ContentStoreItem style) async {
    setState(() {
      _isDownloadingStyle = true;
    });

    Completer<bool> completer = Completer<bool>();
    style.asyncDownload(
      (err) {
        final isSuccess = err == GemError.success;
        completer.complete(isSuccess);

        setState(() {
          _isDownloadingStyle = false;
        });
      },
      onProgressCallback: (progress) {
        // Gets called every time download progresses with a value between [0, 100]
        print('progress: $progress');
      },
      allowChargedNetworks: true,
    );
    return await completer.future;
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

  // Method to change the current style
  Future<void> _onMapButtonTap(BuildContext context) async {
    if (_stylesList.isEmpty) {
      getStyles();
      return;
    }

    final indexOfNextStyle = (_indexOfCurrentStyle + 1) % _stylesList.length;
    ContentStoreItem currentStyle = _stylesList[indexOfNextStyle];

    if (!currentStyle.isCompleted) {
      final didDownloadSuccessfully = await _downloadStyle(currentStyle);
      if (!didDownloadSuccessfully) return;
    }

    _indexOfCurrentStyle = indexOfNextStyle;

    final String filename = currentStyle.fileName;
    _mapController.preferences.setMapStyleByPath(filename);

    setState(() {});
  }
}
