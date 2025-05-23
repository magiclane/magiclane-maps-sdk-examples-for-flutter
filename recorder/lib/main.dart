// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:gem_kit/sense.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:recorder/utils.dart';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recorder',
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
  late Recorder _recorder;

  PermissionStatus _locationPermissionStatus = PermissionStatus.denied;
  bool _hasLiveDataSource = false;
  bool _isRecording = false;
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
        title: const Text('Recorder', style: TextStyle(color: Colors.white)),
        actions: [
          if (_hasLiveDataSource && _isRecording == false)
            IconButton(
              onPressed: _onRecordButtonPressed,
              icon: Icon(Icons.radio_button_on, color: Colors.white),
            ),
          if (_isRecording)
            IconButton(
              onPressed: _onStopRecordingButtonPressed,
              icon: Icon(Icons.stop_circle, color: Colors.white),
            ),
          IconButton(
            onPressed: _onFollowPositionButtonPressed,
            icon: const Icon(
              Icons.location_searching_sharp,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GemMap(
            key: ValueKey("GemMap"),
            onMapCreated: (controller) => _onMapCreated(controller),
            appAuthorization: projectApiToken,
          ),
        ],
      ),
    );
  }

  // The callback for when map is ready to use.
  void _onMapCreated(GemMapController controller) async {
    // Save controller for further usage.
    _mapController = controller;
  }

  Future<void> _onFollowPositionButtonPressed() async {
    if (kIsWeb) {
      // On web platform permission are handled differently than other platforms.
      // The SDK handles the request of permission for location.
      final locationPermssionWeb =
          await PositionService.requestLocationPermission();
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
        PositionService.instance.setLiveDataSource();
        _hasLiveDataSource = true;
      }

      // Optionally, we can set an animation
      final animation = GemAnimation(type: AnimationType.linear);

      // Calling the start following position SDK method.
      _mapController.startFollowingPosition(animation: animation);

      setState(() {});
    }
  }

  Future<void> _onRecordButtonPressed() async {
    // Helper function that returns path to the Tracks directory
    final logsDir = await getDirectoryPath("Tracks");

    final recorder = Recorder.create(
      RecorderConfiguration(
        dataSource: DataSource.createLiveDataSource()!,
        logsDir: logsDir,
        recordedTypes: [DataType.position],
        minDurationSeconds: 0,
      ),
    );

    setState(() {
      _isRecording = true;
      _recorder = recorder;
    });

    await _recorder.startRecording();

    // Clear displayed paths
    _mapController.preferences.paths.clear();
    _mapController.deactivateAllHighlights();
  }

  Future<void> _onStopRecordingButtonPressed() async {
    final endErr = await _recorder.stopRecording();

    if (endErr == GemError.success) {
      await _presentRecordedRoute();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording failed: $endErr'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }

    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _presentRecordedRoute() async {
    final logsDir = await getDirectoryPath("Tracks");

    // It loads all .gm and .mp4 files at logsDir
    final bookmarks = RecorderBookmarks.create(logsDir);

    // Get all recordings path
    final logList = bookmarks?.getLogsList();

    // Get the LogMetadata to obtain details about recorded session
    LogMetadata meta = bookmarks!.getLogMetadata(logList!.last);
    final recorderCoordinates = meta.preciseRoute;
    final duration = convertDuration(meta.durationMillis);

    // Create a path entity from coordinates
    final path = Path.fromCoordinates(recorderCoordinates);

    Landmark beginLandmark = Landmark.withCoordinates(
      recorderCoordinates.first,
    );
    Landmark endLandmark = Landmark.withCoordinates(recorderCoordinates.last);

    beginLandmark.setImageFromIcon(GemIcon.waypointStart);
    endLandmark.setImageFromIcon(GemIcon.waypointFinish);

    HighlightRenderSettings renderSettings = HighlightRenderSettings(
      options: {HighlightOptions.showLandmark},
    );

    _mapController.activateHighlight(
      [beginLandmark, endLandmark],
      renderSettings: renderSettings,
      highlightId: 1,
    );

    // Show the path immediately after stopping recording
    _mapController.preferences.paths.add(path);

    // Center on recorder path
    _mapController.centerOnAreaRect(
      path.area,
      viewRc: RectType(
        x: _mapController.viewport.width ~/ 3,
        y: _mapController.viewport.height ~/ 3,
        width: _mapController.viewport.width ~/ 3,
        height: _mapController.viewport.height ~/ 3,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Duration: $duration'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
}
