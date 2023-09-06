import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:gem_kit/api/gem_coordinates.dart';
import 'package:gem_kit/api/gem_landmark.dart';
import 'package:gem_kit/api/gem_landmarkstore.dart';
import 'package:gem_kit/api/gem_landmarkstoreservice.dart';
import 'package:gem_kit/api/gem_mapviewrendersettings.dart';
import 'package:gem_kit/api/gem_routingservice.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/widget/gem_kit_map.dart';

import 'favorites_page.dart';
import 'landmark_panel.dart';
import 'utility.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Save favorites example',
      home: MyHomePage(),
    );
  }
}

// Model class which contains information about the landmark
class PanelInfo {
  Uint8List? image;
  String name;
  String categoryName;
  String formattedCoords;

  PanelInfo(
      {this.image,
      required this.name,
      required this.categoryName,
      required this.formattedCoords});
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Landmark? _focusedLandmark;

  // GemMapController object used to interact with the map
  late GemMapController _mapController;

  // SdkSettings object to initialize the SDK
  late SdkSettings _sdkSettings;

  // LandmarkStoreServiceObject to get or create the LandmarkStore
  late LandmarkStoreService _landmarkStoreService;

  // LandmarkStore object to save Landmarks
  late LandmarkStore? _favoritesStore;

  late bool _isLandmarkFavorite;

  final favoritesStoreName = 'Favorites';

  final _token = 'YOUR_API_KEY';

  @override
  void initState() {
    super.initState();
  }

  Future<void> onMapCreated(GemMapController controller) async {
    _mapController = controller;
    _focusedLandmark = null;
    _isLandmarkFavorite = false;

    SdkSettings.setAppAuthorization(_token);

    // Instantiate the LandmarkStoreService.
    _landmarkStoreService = await LandmarkStoreService.create(controller.mapId);

    // Retrieves the LandmarkStore with the given name.
    _favoritesStore =
        await _landmarkStoreService.getLandmarkStoreByName(favoritesStoreName);

    // If there is no LandmarkStore with this name, then create it.
    _favoritesStore ??=
        await _landmarkStoreService.createLandmarkStore(favoritesStoreName);

    // Listen for map landmark selection events.
    _registerLandmarkTapCallback();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[900],
        title: const Text('Favourites'),
        actions: [
          IconButton(
              onPressed: () => _onFavouritesButtonPressed(context),
              icon: const Icon(Icons.favorite))
        ],
      ),
      body: Center(
        child: Stack(children: [
          GemMap(
            onMapCreated: onMapCreated,
          ),
          if (_focusedLandmark != null)
            Positioned(
              bottom: 30,
              left: 10,
              child: FutureBuilder<PanelInfo>(
                  future: getInfo(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container();
                    }
                    return LandmarkPanel(
                      onCancelTap: onCancelTap,
                      onFavoritesTap: onFavoritesTap,
                      isFavoriteLandmark: _isLandmarkFavorite,
                      coords: snapshot.data!.formattedCoords,
                      category: snapshot.data!.name,
                      img: snapshot.data!.image!,
                      name: snapshot.data!.name,
                    );
                  }),
            )
        ]),
      ),
      resizeToAvoidBottomInset: false,
    );
  }

  // This future will retrieve the informations about selected landmark which will be displayed in LandmarkPanel
  Future<PanelInfo> getInfo() async {
    late Uint8List? iconFuture;
    late String nameFuture;
    late Coordinates coordsFuture;
    late String coordsFutureText;
    late List<LandmarkCategory> categoriesFuture;

    iconFuture = await _decodeLandmarkIcon(_focusedLandmark!);
    nameFuture = await _focusedLandmark!.getName();
    coordsFuture = await _focusedLandmark!.getCoordinates();
    coordsFutureText =
        "${coordsFuture.latitude.toString()}, ${coordsFuture.longitude.toString()}";
    categoriesFuture = await _focusedLandmark!.getCategories();

    return PanelInfo(
        image: iconFuture,
        name: nameFuture,
        categoryName:
            categoriesFuture.isNotEmpty ? categoriesFuture.first.name! : '',
        formattedCoords: coordsFutureText);
  }

  Future<Uint8List?> _decodeLandmarkIcon(Landmark landmark) async {
    final data = await landmark.getImage(100, 100);

    return decodeImageData(data);
  }

  _registerLandmarkTapCallback() {
    _mapController.registerTouchCallback((pos) async {
      // Select the object at the tap position.
      await _mapController.selectMapObjects(pos);

      // Get the selected landmarks.
      final landmarks = await _mapController.cursorSelectionLandmarks();

      final landmarksSize = await landmarks.size();

      // Check if there is a selected Landmark.
      if (landmarksSize == 0) return;

      // Highlight the landmark on the map.
      _mapController.activateHighlight(landmarks);

      final lmk = await landmarks.at(0);
      setState(() {
        _focusedLandmark = lmk;
      });

      await _checkIfFavourite();
    });
  }

  // Method to navigate to the Favourites Page.
  _onFavouritesButtonPressed(BuildContext context) async {
    // Fetch landmarks from the store
    final favoritesList = await _favoritesStore!.getLandmarks();

    // Navigating to favorites screen then the result will be the selected item in the list.
    final result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => FavoritesPage(landmarkList: favoritesList),
    ));

    // Create a list of landmarks to highlight.
    LandmarkList landmarkList = await LandmarkList.create(_mapController.mapId);

    if (result is! Landmark) {
      return;
    }

    // Add the result to the landmark list.
    await landmarkList.push_back(result);
    final coords = await result.getCoordinates();

    // Highlight the landmark on the map.
    await _mapController.activateHighlight(landmarkList,
        renderSettings: RenderSettings());

    // Centering the camera on landmark's coordinates
    await _mapController.centerOnCoordinates(coords);

    setState(() {
      _focusedLandmark = result;
    });
    await _checkIfFavourite();
  }

  void onCancelTap() {
    // Remove landmark highlights from the map
    _mapController.deactivateAllHighlights();

    setState(() {
      _focusedLandmark = null;
      _isLandmarkFavorite = false;
    });
  }

  void onFavoritesTap() async {
    await _checkIfFavourite();

    if (_isLandmarkFavorite) {
      // Remove the landmark to the store.
      await _favoritesStore!.removeLandmark(_focusedLandmark!);
    } else {
      // Add the landmark to the store.
      await _favoritesStore!.addLandmark(_focusedLandmark!);
    }

    setState(() {
      _isLandmarkFavorite = !_isLandmarkFavorite;
    });
  }

  // Utility method to check if the highlighted landmark is favourite
  _checkIfFavourite() async {
    final focusedLandmarkCoords = await _focusedLandmark!.getCoordinates();
    final favourites = await _favoritesStore!.getLandmarks();
    final favoritesSize = await favourites.size();

    for (int i = 0; i < favoritesSize; i++) {
      final lmk = await favourites.at(i);
      final coords = await lmk.getCoordinates();

      if (focusedLandmarkCoords.latitude == coords.latitude &&
          focusedLandmarkCoords.longitude == coords.longitude) {
        setState(() {
          _isLandmarkFavorite = true;
        });
        return;
      }
    }

    setState(() {
      _isLandmarkFavorite = false;
    });
  }
}
