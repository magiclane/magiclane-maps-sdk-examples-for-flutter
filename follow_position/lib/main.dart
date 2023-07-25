import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gem_kit/api/gem_mapviewpreferences.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/gem_kit_position.dart';
import 'package:gem_kit/widget/gem_kit_map.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const FollowPositionApp());
}

class FollowPositionApp extends StatelessWidget {
  const FollowPositionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Follow Position',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const FollowPositionPage());
  }
}

class FollowPositionPage extends StatefulWidget {
  const FollowPositionPage({super.key});

  @override
  State<FollowPositionPage> createState() => _FollowPositionPageState();
}

class _FollowPositionPageState extends State<FollowPositionPage> {
  late GemMapController _mapController;
  late PermissionStatus _locationPermissionStatus = PermissionStatus.denied;

  late PositionService _positionService;
  late bool _hasLiveDataSource = false;

  final token = 'YOUR_API_TOKEN';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[900],
        title: const Text('Follow Position',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
              onPressed: _onFollowPositionButtonPressed,
              icon: const Icon(
                CupertinoIcons.location,
                color: Colors.white,
              ))
        ],
      ),
      body: GemMap(
        onMapCreated: _onMapCreatedCallback,
      ),
    );
  }

  // The callback for when map is ready to use
  _onMapCreatedCallback(GemMapController controller) async {
    // Save controller for further usage
    _mapController = controller;

    // Create the position service
    _positionService = await PositionService.create(controller.mapId);

    final settings = await SdkSettings.create(controller.mapId);

    settings.setAppAuthorization(token);
  }

  _onFollowPositionButtonPressed() async {
    if (kIsWeb) {
      // On web platform permission are handled differently than other platforms.
      // The SDK handles the request of permission for location
      _locationPermissionStatus = PermissionStatus.granted;
    } else {
      // For Android & iOS platforms, permission_handler package is used to ask for permissions
      _locationPermissionStatus = await Permission.locationWhenInUse.request();
    }

    if (_locationPermissionStatus != PermissionStatus.granted) {
      return;
    }

    // After the permission was granted, we can set the live data source (in most cases the GPS)
    // The data source should be set only once, otherwise we'll get -5 error
    if (!_hasLiveDataSource) {
      _positionService.setLiveDataSource();
      _hasLiveDataSource = true;
    }

    // After data source is set, startFollowingPosition can be safely called
    if (_locationPermissionStatus == PermissionStatus.granted) {
      // Optionally, we can set an animation
      final animation = GemAnimation(type: EAnimation.AnimationLinear);

      _mapController.startFollowingPosition(animation: animation);
    }
    setState(() {});
  }
}
