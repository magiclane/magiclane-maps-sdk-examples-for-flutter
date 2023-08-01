import 'package:flutter/material.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/widget/gem_kit_map.dart';

void main() {
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
  int _mapViewsCount = 0;
  final token = 'YOUR_API_KEY_TOKEN';

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
                icon: const Icon(
                  Icons.add,
                  color: Colors.white,
                )),
            IconButton(
                onPressed: _onRemoveViewButtonPressed,
                icon: const Icon(
                  Icons.remove,
                  color: Colors.white,
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
                    onMapCreated: (controller) async {
                      final settings =
                          await SdkSettings.create(controller.mapId);
                      await settings.setAppAuthorization(token);
                    },
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
