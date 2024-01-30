import 'search_page.dart';

import 'package:gem_kit/api/gem_landmark.dart';
import 'package:gem_kit/api/gem_mapviewrendersettings.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/api/gem_types.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/gem_kit_platform_interface.dart';
import 'package:gem_kit/widget/gem_kit_map.dart';

import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      title: 'Search Location',
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
  late GemMapController _mapController;

  @override
  void initState() {
    super.initState();
  }

  Future<void> onMapCreated(GemMapController controller) async {
    _mapController = controller;
  }

  // Custom method for navigating to search screen
  _onPressed(BuildContext context) async {
    // Taking the coordinates at the center of the screen as reference coordinates for search.
    final x = MediaQuery.of(context).size.width / 2;
    final y = MediaQuery.of(context).size.height / 2;
    final mapCoords =
        _mapController.transformScreenToWgs(XyType(x: x.toInt(), y: y.toInt()));

    // Navigating to search screen. The result will be the selected search result(Landmark)
    final result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SearchPage(
        controller: _mapController,
        coordinates: mapCoords!,
      ),
    ));

    if (result == null) return;

    // Creating a list of landmarks to highlight.
    LandmarkList landmarkList = LandmarkList.create();

    if (result is! Landmark) {
      return;
    }

    // Adding the result to the landmark list.
    landmarkList.push_back(result);
    final coords = result.getCoordinates();

    // Activating the highlight
    _mapController.activateHighlight(landmarkList,
        renderSettings: RenderSettings());

    // Centering the map on the desired coordinates
    _mapController.centerOnCoordinates(coords);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GemMap(
          onMapCreated: onMapCreated,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple[900],
        foregroundColor: Colors.white,
        onPressed: () => _onPressed(context),
        child: const Icon(Icons.search),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
