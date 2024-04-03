import 'package:flutter/material.dart';
import 'package:gem_kit/api/cui_imageids.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/gem_kit_platform_interface.dart';
import 'package:gem_kit/widget/gem_kit_map.dart';

import "dart:ui" as ui;

void main() {
  const token = 'YOUR_API_TOKEN';
  GemKitPlatform.instance.loadNative().then((value) {
    SdkSettings.setAppAuthorization(token);
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Map Compass',
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
  late GemMapController mapController;

  ui.Image? compassImage;
  double compassAngle = 0;

  @override
  void initState() {
    super.initState();
  }

  onMapCreated(GemMapController controller) async {
    await compassImageIcon();

    mapController = controller;

    mapController.registerOnMapAngleUpdate(
      (p0) {
        setState(() => compassAngle = p0);
      },
    );
  }

  compassImageIcon() async {
    compassImage = await SdkSettings.getImageById(Engine_Misc.CompassEnable_SensorOFF.id, 100, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.deepPurple[900],
        title: const Text(
          "Map Compass",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Stack(
          children: [
            GemMap(
              onMapCreated: onMapCreated,
            ),
            if (compassImage != null)
              Positioned(
                right: 12,
                top: 12,
                child: InkWell(
                  onTap: () => mapController.alignNorthUp(),
                  child: Transform.rotate(
                    angle: -compassAngle * (3.141592653589793 / 180),
                    child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: SizedBox(
                            width: 40,
                            height: 40,
                            child: RawImage(
                              image: compassImage,
                            ))),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
