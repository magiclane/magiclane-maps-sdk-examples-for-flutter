import 'package:gem_kit/api/gem_mapviewpreferences.dart';
import 'package:gem_kit/api/gem_sdksettings.dart';
import 'package:gem_kit/gem_kit_map_controller.dart';
import 'package:gem_kit/gem_kit_platform_interface.dart';
import 'package:gem_kit/widget/gem_kit_map.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  const token = "YOUR_API_TOKEN";
  GemKitPlatform.instance.loadNative().then((value) {
    SdkSettings.setAppAuthorization(token);
  });
  runApp(const PerspectiveMapApp());
}

class PerspectiveMapApp extends StatelessWidget {
  const PerspectiveMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Perspective Map',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const PerspectiveMapPage());
  }
}

class PerspectiveMapPage extends StatefulWidget {
  const PerspectiveMapPage({super.key});

  @override
  State<PerspectiveMapPage> createState() => _PerspectiveMapPageState();
}

class _PerspectiveMapPageState extends State<PerspectiveMapPage> {
  // Map preferences are used to change map perspective
  late MapViewPreferences _mapPreferences;

  late bool _isInPerspectiveView = false;

  // Tilt angle for perspective view
  final double _3dViewAngle = 30;

  // Tilt angle for orthogonal/vertical view
  final double _2dViewAngle = 90;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[900],
        title: const Text('Perspective Map',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
              onPressed: _onChangePersectiveButtonPressed,
              icon: Icon(
                _isInPerspectiveView
                    ? CupertinoIcons.view_2d
                    : CupertinoIcons.view_3d,
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
    _mapPreferences = controller.preferences();
  }

  _onChangePersectiveButtonPressed() async {
    setState(() => _isInPerspectiveView = !_isInPerspectiveView);

    // Based on view type, set the view angle
    if (_isInPerspectiveView) {
      _mapPreferences.setTiltAngle(_3dViewAngle);
    } else {
      _mapPreferences.setTiltAngle(_2dViewAngle);
    }
  }
}
