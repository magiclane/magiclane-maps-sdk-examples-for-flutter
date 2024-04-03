import 'dart:typed_data';

import 'package:gem_kit/api/gem_images.dart';

import 'favorites_page.dart';
import 'landmark_panel.dart';

import 'package:gem_kit/api/gem_coordinates.dart';
import 'package:gem_kit/api/gem_landmark.dart';
import 'package:gem_kit/api/gem_landmarkstore.dart';
import 'package:gem_kit/api/gem_landmarkstoreservice.dart';
import 'package:gem_kit/api/gem_mapviewrendersettings.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
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
      title: 'Save favorites example',
      home: MyHomePage(),
    );
  }
}

// Model class which contains information about the landmark
class PanelInfo {
  Uint8List image;
  String name;
  String categoryName;
  String formattedCoords;

  PanelInfo({required this.image, required this.name, required this.categoryName, required this.formattedCoords});
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

  // LandmarkStore object to save Landmarks
  late LandmarkStore? _favoritesStore;

  late bool _isLandmarkFavorite;

  final favoritesStoreName = 'Favorites';

  @override
  void initState() {
    super.initState();
  }

  Future<void> onMapCreated(GemMapController controller) async {
    _mapController = controller;
    _focusedLandmark = null;
    _isLandmarkFavorite = false;

    // Instantiate the LandmarkStoreService.

    // Retrieves the LandmarkStore with the given name.
    _favoritesStore = LandmarkStoreService.getLandmarkStoreByName(favoritesStoreName);

    // If there is no LandmarkStore with this name, then create it.
    _favoritesStore ??= LandmarkStoreService.createLandmarkStore(favoritesStoreName);

    // Listen for map landmark selection events.
    _registerLandmarkTapCallback();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.deepPurple[900],
        title: const Text('Favourites'),
        actions: [IconButton(onPressed: () => _onFavouritesButtonPressed(context), icon: const Icon(Icons.favorite))],
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
                      img: snapshot.data!.image,
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
    late Uint8List icon;
    late String nameFuture;
    late Coordinates coordsFuture;
    late String coordsFutureText;
    late List<LandmarkCategory> categoriesFuture;

    icon = _focusedLandmark!.getImage(48, 48, EImageFileFormat.IFF_Png);
    nameFuture = _focusedLandmark!.getName();
    coordsFuture = _focusedLandmark!.getCoordinates();
    coordsFutureText = "${coordsFuture.latitude.toString()}, ${coordsFuture.longitude.toString()}";
    categoriesFuture = _focusedLandmark!.getCategories().toList();

    return PanelInfo(
        image: icon,
        name: nameFuture,
        categoryName: categoriesFuture.isNotEmpty ? categoriesFuture.first.getName() : '',
        formattedCoords: coordsFutureText);
  }

  _registerLandmarkTapCallback() {
    _mapController.registerTouchCallback((pos) async {
      // Select the object at the tap position.
      await _mapController.selectMapObjects(pos);

      // Get the selected landmarks.
      final landmarks = _mapController.cursorSelectionLandmarks();

      final landmarksSize = landmarks.size();

      // Check if there is a selected Landmark.
      if (landmarksSize == 0) return;

      // Highlight the landmark on the map.
      _mapController.activateHighlight(landmarks);

      final lmk = landmarks.at(0);
      setState(() {
        _focusedLandmark = lmk;
      });

      _checkIfFavourite();
    });
  }

  // Method to navigate to the Favourites Page.
  _onFavouritesButtonPressed(BuildContext context) async {
    // Fetch landmarks from the store
    final favoritesList = _favoritesStore!.getLandmarks();

    // Navigating to favorites screen then the result will be the selected item in the list.
    final result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => FavoritesPage(landmarkList: favoritesList),
    ));

    // Create a list of landmarks to highlight.
    LandmarkList landmarkList = LandmarkList.create();

    if (result is! Landmark) {
      return;
    }

    // Add the result to the landmark list.
    landmarkList.push_back(result);
    final coords = result.getCoordinates();

    // Highlight the landmark on the map.
    _mapController.activateHighlight(landmarkList, renderSettings: RenderSettings());

    // Centering the camera on landmark's coordinates
    _mapController.centerOnCoordinates(coords);

    setState(() {
      _focusedLandmark = result;
    });
    _checkIfFavourite();
  }

  void onCancelTap() {
    // Remove landmark highlights from the map
    _mapController.deactivateAllHighlights();

    setState(() {
      _focusedLandmark = null;
      _isLandmarkFavorite = false;
    });
  }

  void onFavoritesTap() {
    _checkIfFavourite();

    if (_isLandmarkFavorite) {
      // Remove the landmark to the store.
      _favoritesStore!.removeLandmark(_focusedLandmark!);
    } else {
      // Add the landmark to the store.
      _favoritesStore!.addLandmark(_focusedLandmark!);
    }

    setState(() {
      _isLandmarkFavorite = !_isLandmarkFavorite;
    });
  }

  // Utility method to check if the highlighted landmark is favourite
  _checkIfFavourite() {
    final focusedLandmarkCoords = _focusedLandmark!.getCoordinates();
    final favourites = _favoritesStore!.getLandmarks();
    final favoritesSize = favourites.size();

    for (int i = 0; i < favoritesSize; i++) {
      final lmk = favourites.at(i);
      late Coordinates coords;
      coords = lmk.getCoordinates();

      if (focusedLandmarkCoords.latitude == coords.latitude && focusedLandmarkCoords.longitude == coords.longitude) {
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
