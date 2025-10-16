// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'dart:math';

import 'package:recorder_in_background/foreground_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/sense.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:recorder_in_background/utils.dart';

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
      title: 'Background Location - Android only',
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
  PermissionStatus _notificationPermissionStatus = PermissionStatus.denied;

  bool _hasLiveDataSource = false;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isRecorder = false;

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
        title: const Text('Background Location', style: TextStyle(color: Colors.white)),
        actions: [
          if (_hasLiveDataSource && _isRecording == false)
            IconButton(
              onPressed: _startRecording,
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
    // Ask for notifications permission too
    if (_notificationPermissionStatus != PermissionStatus.granted) {
      _notificationPermissionStatus = await Permission.notification.request();
    }

    if (kIsWeb) {
      final locationPermissionWeb = await PositionService.requestLocationPermission();
      _locationPermissionStatus = locationPermissionWeb == true ? PermissionStatus.granted : PermissionStatus.denied;
    } else {
      // Request WhenInUse permission first
      final whenInUseStatus = await Permission.locationWhenInUse.request();

      if (whenInUseStatus == PermissionStatus.granted) {
        // Then request Always (background) permission
        final backgroundStatus = await Permission.locationAlways.request();
        _locationPermissionStatus = backgroundStatus;
      } else {
        _locationPermissionStatus = whenInUseStatus; // denied or restricted
      }
    }

    if (_locationPermissionStatus == PermissionStatus.granted) {
      if (!_hasLiveDataSource) {
        PositionService.setLiveDataSource();
        _hasLiveDataSource = true;
      }

      final animation = GemAnimation(type: AnimationType.linear);
      _mapController.startFollowingPosition(animation: animation);

      setState(() {});
    }
  }

  Future<void> _initializeForegroundService() async {
    if (await AndroidForegroundService.hasGrantedPermission() == true) {
      await AndroidForegroundService.initialize(true);

      setState(() {
        _isInitialized = true;
      });
    } else {
      // ignore: avoid_print
      print("No permission for foreground service");
    }
  }

  Future<void> _createRecorder() async {
    final dataSource = DataSource.createLiveDataSource()!;
    final config = dataSource.getConfiguration(DataType.position);
    config.allowsBackgroundLocationUpdates = true;
    dataSource.setConfiguration(type: DataType.position, config: config);

    final logsDir = await getDirectoryPath("Tracks");

    _recorder = Recorder.create(
      RecorderConfiguration(
        dataSource: dataSource,
        logsDir: logsDir,
        recordedTypes: [DataType.position],
        minDurationSeconds: 0,
      ),
    );

    setState(() {
      _isRecorder = true;
    });
  }

  Future<void> _startRecording() async {
    if (!_isInitialized) {
      await _initializeForegroundService();
    }

    AndroidForegroundService.start();

    if (!_isRecorder) {
      await _createRecorder();
    }

    await _recorder.startRecording();

    // Clear displayed paths
    _mapController.preferences.paths.clear();
    _mapController.deactivateAllHighlights();

    setState(() {
      _isRecording = true;
    });
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

    AndroidForegroundService.stop();

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
    LogMetadata? meta = bookmarks!.getLogMetadata(logList!.last);
    if (meta == null) {
      // Handle the case where metadata is not found
      return;
    }
    final recorderCoordinates = meta.preciseRoute;
    final duration = convertDuration(meta.durationMillis);

    if (recorderCoordinates.isEmpty) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No recorded coordinates.'),
          duration: Duration(seconds: 5),
        ),
      );
    }

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
      viewRc: Rectangle(
        _mapController.viewport.width ~/ 3,
        _mapController.viewport.height ~/ 3,
        _mapController.viewport.width ~/ 3,
        _mapController.viewport.height ~/ 3,
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
