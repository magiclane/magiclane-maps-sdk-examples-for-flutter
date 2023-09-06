import 'package:flutter/material.dart';
import 'package:gem_kit/api/gem_landmark.dart';
import 'package:gem_kit/api/gem_landmarkstoreservice.dart';
import 'package:gem_kit/api/gem_mapviewrendersettings.dart';
import 'package:gem_kit/api/gem_routingservice.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/api/gem_types.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/widget/gem_kit_map.dart';
import '../search_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Search example',
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
  late LandmarkStoreService _landmarkStoreService;

  final _token = 'YOUR_API_KEY';

  @override
  void initState() {
    super.initState();
  }

  Future<void> onMapCreated(GemMapController controller) async {
    _mapController = controller;
    SdkSettings.setAppAuthorization(_token);

    _landmarkStoreService = await LandmarkStoreService.create(controller.mapId);
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

    var historyStore =
        await _landmarkStoreService.getLandmarkStoreByName("History");

    if (historyStore == null) {
      historyStore = await _landmarkStoreService.createLandmarkStore("History");

      await historyStore.addLandmark(result);
    }

// Creating a list of landmarks to highlight.
    LandmarkList landmarkList = await LandmarkList.create(_mapController.mapId);

    if (result is! Landmark) {
      return;
    }

// Adding the result to the landmark list.
    await landmarkList.push_back(result);
    final coords = result.getCoordinates();

// Activating the highlight
    await _mapController.activateHighlight(landmarkList,
        renderSettings: RenderSettings());

// Centering the map on the desired coordinates
    await _mapController.centerOnCoordinates(coords);
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
        onPressed: () => _onPressed(context),
        child: const Icon(Icons.search),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
