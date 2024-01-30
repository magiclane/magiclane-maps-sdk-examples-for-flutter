import 'package:gem_kit/api/gem_contentstore.dart';
import 'package:gem_kit/api/gem_contentstoreitem.dart';
import 'package:gem_kit/api/gem_contenttypes.dart';
import 'package:gem_kit/api/gem_offboardlistener.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/gem_kit_basic.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/gem_kit_platform_interface.dart';
import 'package:gem_kit/widget/gem_kit_map.dart';

import 'package:flutter/material.dart';

import 'dart:async';

void main() {
  const token = "YOUR_API_TOKEN";
  GemKitPlatform.instance.loadNative().then((value) {
    SdkSettings.setAppAuthorization(token);
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Map styles',
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

  List<ContentStoreItem> stylesList = [];
  int indexOfCurrentStyle = 0;
  bool isDownloadingStyle = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> onMapCreated(GemMapController controller) async {
    _mapController = controller;
    SdkSettings.setAllowOffboardServiceOnExtraChargedNetwork(
        EServiceGroupType.ContentService, true);
    await getStyles();
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
          if (isDownloadingStyle == true)
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
      body: Center(
        child: GemMap(
          onMapCreated: onMapCreated,
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }

  // Method to load the styles
  Future<void> getStyles() async {
    await ContentStore.asyncGetStoreContentList(EContentType.CT_ViewStyleLowRes,
        (err, items, isCached) {
      if (err != GemError.success || items == null) {
        return;
      }

      for (final item in items) {
        stylesList.add(item);
      }
      ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  // Method to download a style
  Future<bool> _downloadStyle(ContentStoreItem style) async {
    setState(() {
      isDownloadingStyle = true;
    });
    Completer<bool> completer = Completer<bool>();
    await style.asyncDownload((err) {
      if (err != GemError.success) {
        // An error was encountered during download
        completer.complete(false);
        setState(() {
          isDownloadingStyle = false;
        });
        return;
      }
      // Download was succesful
      completer.complete(true);
      setState(() {
        isDownloadingStyle = false;
      });
    }, onProgressCallback: (progress) {
      // Gets called everytime download progresses with a value between [0, 100]
      print('progress: $progress');
    }, allowChargedNetworks: true);
    return await completer.future;
  }

  // Method to show message in case the styles are still loading
  void _showSnackBar(BuildContext context) {
    const snackBar = SnackBar(
      content: Text("The map styles are loading"),
      duration: Duration(hours: 1),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Method to change the current style
  Future<void> _onMapButtonTap(BuildContext context) async {
    if (stylesList.isEmpty) {
      _showSnackBar(context);
      await getStyles();
      return;
    }

    final indexOfNextStyle = (indexOfCurrentStyle >= stylesList.length - 1)
        ? 0
        : indexOfCurrentStyle + 1;
    ContentStoreItem currentStyle = stylesList[indexOfNextStyle];

    if (currentStyle.isCompleted() == false) {
      final didDownloadSucessfully = await _downloadStyle(currentStyle);
      if (didDownloadSucessfully == false) return;
    }

    indexOfCurrentStyle = indexOfNextStyle;

    final String filename = currentStyle.getFileName();
    await _mapController.preferences().setMapStyleByPath(filename);
    setState(() {});
  }
}
