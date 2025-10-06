// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/routing.dart';
import 'package:magiclane_maps_flutter/sense.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Animation;
import 'package:social_report/social_event_panel.dart';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Social Report', debugShowCheckedModeBanner: false, home: MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late GemMapController _mapController;

  PermissionStatus _locationPermissionStatus = PermissionStatus.denied;
  bool _hasLiveDataSource = false;

  // Current selected overlay item
  OverlayItem? _selectedItem;

  @override
  void dispose() {
    GemKit.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[900],
        title: const Text('Social Report', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: _onFollowPositionButtonPressed,
            icon: const Icon(Icons.location_searching_sharp, color: Colors.white),
          ),
          if (_hasLiveDataSource)
            IconButton(
              onPressed: _onPrepareReportingButtonPressed,
              icon: Icon(Icons.report, color: Colors.white),
            ),
        ],
      ),
      body: Stack(
        children: [
          GemMap(key: ValueKey("GemMap"), onMapCreated: _onMapCreated, appAuthorization: projectApiToken),
          if (_selectedItem != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SocialEventPanel(
                  overlayItem: _selectedItem!,
                  onClose: () {
                    setState(() {
                      _selectedItem = null;
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // The callback for when map is ready to use.
  void _onMapCreated(GemMapController controller) async {
    // Save controller for further usage.
    _mapController = controller;

    // Register callback for touch events and updated cursor position
    _mapController.registerOnTouch((point) {
      _mapController.setCursorScreenPosition(point);
    });

    // Get selected overlay items under cursor
    _mapController.registerOnCursorSelectionUpdatedOverlayItems((items) {
      if (items.isEmpty) return;
      final selectedItem = items.first;

      // Update selected item
      setState(() {
        _selectedItem = selectedItem;
      });
    });
  }

  void _onFollowPositionButtonPressed() async {
    if (kIsWeb) {
      // On web platform permission are handled differently than other platforms.
      // The SDK handles the request of permission for location.
      final locationPermssionWeb = await PositionService.requestLocationPermission();
      if (locationPermssionWeb == true) {
        _locationPermissionStatus = PermissionStatus.granted;
      } else {
        _locationPermissionStatus = PermissionStatus.denied;
      }
    } else {
      // For Android & iOS platforms, permission_handler package is used to ask for permissions.
      _locationPermissionStatus = await Permission.locationWhenInUse.request();
    }

    if (_locationPermissionStatus == PermissionStatus.granted) {
      // After the permission was granted, we can set the live data source (in most cases the GPS).
      // The data source should be set only once, otherwise we'll get -5 error.
      if (!_hasLiveDataSource) {
        PositionService.setLiveDataSource();
        _hasLiveDataSource = true;
      }

      // Optionally, we can set an animation
      final animation = GemAnimation(type: AnimationType.linear);

      // Calling the start following position SDK method.
      _mapController.startFollowingPosition(animation: animation);

      setState(() {});
    }
  }

  void _onPrepareReportingButtonPressed() async {
    // Get current position quality
    final improvedPos = PositionService.improvedPosition;
    final posQuality = improvedPos!.fixQuality;

    if (posQuality == PositionQuality.invalid || posQuality == PositionQuality.inertial) {
      _showSnackBar(context, message: "There is no accurate position at the moment.", duration: Duration(seconds: 3));
      return;
    }

    // Get the reporting id (uses current position). Requires accurate position, may return GemError.notFound when in buildings/tunnels etc.
    int idReport = SocialOverlay.prepareReporting();

    // Get the subcategory id
    SocialReportsOverlayInfo info = SocialOverlay.reportsOverlayInfo;
    List<SocialReportsOverlayCategory> categs = info.getSocialReportsCategories();
    SocialReportsOverlayCategory cat = categs.first;
    List<SocialReportsOverlayCategory> subcats = cat.overlaySubcategories;
    SocialReportsOverlayCategory subCategory = subcats.first;

    // Report
    SocialOverlay.report(
      prepareId: idReport,
      categId: subCategory.uid,
      onComplete: (error) {
        _showSnackBar(context, message: "Added report error: $error.", duration: Duration(seconds: 3));
      },
    );
  }

  // Show a snackbar indicating that the route calculation is in progress.
  void _showSnackBar(BuildContext context, {required String message, Duration duration = const Duration(hours: 1)}) {
    final snackBar = SnackBar(content: Text(message), duration: duration);

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
