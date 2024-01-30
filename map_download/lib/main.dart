import 'maps_page.dart';

import 'package:gem_kit/api/gem_offboardlistener.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/gem_kit_platform_interface.dart';
import 'package:gem_kit/widget/gem_kit_map.dart';

import 'package:flutter/material.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const token = 'YOUR_API_TOKEN';
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
      title: 'Map download',
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
  @override
  void initState() {
    super.initState();
  }

  Future<void> onMapCreated(GemMapController controller) async {
    SdkSettings.setAllowOffboardServiceOnExtraChargedNetwork(
        EServiceGroupType.ContentService, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[900],
        title: const Text(
          'Map Download',
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
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const MapsPage(),
    ));
  }
}
