import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/gem_kit_platform_interface.dart';
import 'package:gem_kit/widget/gem_kit_map.dart';

import 'package:flutter/material.dart';

void main() {
  const token = "YOUR_API_TOKEN";
  GemKitPlatform.instance.loadNative().then((value) {
    SdkSettings.setAppAuthorization(token);
  });
  runApp(const MultiviewMapApp());
}

class MultiviewMapApp extends StatelessWidget {
  const MultiviewMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Multiview Map',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MultiviewMapPage());
  }
}

class MultiviewMapPage extends StatefulWidget {
  const MultiviewMapPage({super.key});

  @override
  State<MultiviewMapPage> createState() => _MultiviewMapPageState();
}

class _MultiviewMapPageState extends State<MultiviewMapPage> {
  late GemMapController mapController;
  int _mapViewsCount = 0;

  Future<void> onMapCreated(GemMapController controller) async {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple[900],
          title: const Text('Multiview Map',
              style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
                onPressed: _onAddViewButtonPressed,
                icon: Icon(
                  Icons.add,
                  color: (_mapViewsCount < 4) ? Colors.white : Colors.grey,
                )),
            IconButton(
                onPressed: _onRemoveViewButtonPressed,
                icon: Icon(
                  Icons.remove,
                  color: (_mapViewsCount != 0) ? Colors.white : Colors.grey,
                ))
          ],
        ),
        // Arrange MapViews in a grid with fixed number on elements on row
        body: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2),
            itemCount: _mapViewsCount,
            itemBuilder: (context, index) {
              return Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.grey,
                            offset: Offset(0, -2),
                            spreadRadius: 1,
                            blurRadius: 2)
                      ]),
                  margin: const EdgeInsets.all(5),
                  child: GemMap(
                    onMapCreated: (controller) => onMapCreated(controller),
                  ));
            }));
  }

  // Add one more view on button press
  _onAddViewButtonPressed() => setState(() {
        if (_mapViewsCount < 4) {
          _mapViewsCount += 1;
        }
      });

  _onRemoveViewButtonPressed() => setState(() {
        if (_mapViewsCount > 0) {
          _mapViewsCount -= 1;
        }
      });
}
