import 'maps_page.dart';

import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/gem_kit_platform_interface.dart';
import 'package:gem_kit/widget/gem_kit_map.dart';

import 'package:flutter/material.dart';
import 'dart:async';

OffBoardListener? offBoardListener;

// In order to test with older map you need to manually modify the app files on the device:
// Put old region .cmap file into \Data\Maps
// Put old VM .map file into \Data\Res
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const token = 'YOUR_API_TOKEN';

  GemKitPlatform.instance.loadNative().then((value) {
    offBoardListener = OffBoardListener.create(false);
    offBoardListener!.registerOnApiTokenUpdated(() {});
    SdkSettings.setAllowConnection(true, offBoardListener!);
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

  @override
  void initState() {
    super.initState();
  }

  void onMapCreated(GemMapController controller) async {
    mapId = controller.mapId;
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
      body: Center(
        child: GemMap(
          onMapCreated: onMapCreated,
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }

  // Method to navigate to the Maps Page.
  void _onMapButtonTap(BuildContext context) async {
    if (mapId == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => MapsPage(mapId: mapId!),
    ));
  }
}
