import 'package:flutter/material.dart';
import 'package:gem_kit/api/gem_landmark.dart';
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
  late SdkSettings _sdkSettings;

  @override
  void initState() {
    super.initState();
  }

  Future<void> onMapCreated(GemMapController controller) async {
    _mapController = controller;
    SdkSettings.create(_mapController.mapId).then((value) {
      _sdkSettings = value;
      _sdkSettings.setAppAuthorization(
          "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiI0ZTZjNmQxMy0yMTFiLTRhOWQtOGViYS1hMDkxNzg5ZWE2NWEiLCJleHAiOjE4ODE1MjIwMDAsImlzcyI6IkdlbmVyYWwgTWFnaWMiLCJqdGkiOiI4MWZkYTI0Zi1iNTVkLTRiNzEtODViZC02N2QzMGFkNGI4MGQiLCJuYmYiOjE2NjU1NzU0NTZ9.czCmTl26q6uw8XnmMv2KffxVwhNFEN82KJNzeYsRfZJVIa9yXvTPtNl-1BjoxaxWgATANCuqUDQrbdqZlsqj7w");
    });
  }

// Custom method for navigating to search screen
  _onPressed(BuildContext context) async {
// Taking the coordinates at the center of the screen as reference coordinates for search.
    final x = MediaQuery.of(context).size.width / 2;
    final y = MediaQuery.of(context).size.height / 2;
    final mapCoords = await _mapController
        .transformScreenToWgs(XyType(x: x.toInt(), y: y.toInt()));

// Navigating to search screen. The result will be the selected search result(Landmark)
    final result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SearchPage(
        controller: _mapController,
        coordinates: mapCoords!,
      ),
    ));

// Creating a list of landmarks to highlight.
    LandmarkList landmarkList = await LandmarkList.create(_mapController.mapId);

    if (result is! Landmark) {
      return;
    }

// Adding the result to the landmark list.
    await landmarkList.push_back(result);
    final coords = await result.getCoordinates();

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
