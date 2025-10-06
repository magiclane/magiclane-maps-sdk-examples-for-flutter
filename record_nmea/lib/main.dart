// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'dart:io';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/sense.dart';
import 'package:permission_handler/permission_handler.dart';

import 'utils.dart';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, title: 'Record NMEA Chunk', home: MyHomePage());
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
  void initState() {
    super.initState();

    if (!Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NMEA Chunk recording is only available on Android devices.'),
            duration: Duration(seconds: 20),
          ),
        );
      });
    }
  }

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
        title: const Text('Record NMEA Chunk', style: TextStyle(color: Colors.white)),
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
            icon: const Icon(Icons.location_searching_sharp, color: Colors.white),
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
      final locationPermssionWeb = await PositionService.requestLocationPermission();
      if (locationPermssionWeb == true) {
        _locationPermissionStatus = PermissionStatus.granted;
      } else {
        _locationPermissionStatus = PermissionStatus.denied;
      }
    } else {
      // For Android & iOS platforms, permission_handler package is used to ask for permissions.
      _locationPermissionStatus = await Permission.locationWhenInUse.request();
      await Permission.manageExternalStorage.request();
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

  Future<void> _onRecordButtonPressed() async {
    // Helper function that returns path to the Tracks directory
    final logsDir = await getDirectoryPath("Tracks");

    final dataSource = DataSource.createLiveDataSource()!;

    // Add listener for NMEA Chunk
    dataSource.addListener(
      listener: DataSourceListener(
        onNewData: (data) {
          final nmeaChunk = data as NmeaChunk;
          // ignore: avoid_print
          print("NMEA Chunk: $nmeaChunk");
        },
      ),
      dataType: DataType.nmeaChunk,
    );

    final recorder = Recorder.create(
      RecorderConfiguration(
        hardwareSpecifications: await getDeviceInfo(),
        dataSource: dataSource,
        logsDir: logsDir,
        recordedTypes: [DataType.position, DataType.nmeaChunk],
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
      await _presentRecordedNmeaData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Recording failed: $endErr'), duration: Duration(seconds: 5)));
      }
    }

    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _presentRecordedNmeaData() async {
    final logsDir = await getDirectoryPath("Tracks");

    // It loads all .gm and .mp4 files at logsDir
    final bookmarks = RecorderBookmarks.create(logsDir);

    // Get all recordings path
    final logList = bookmarks?.getLogsList();

    // Save the log as a CSV
    await _deletePreviousCsv();
    final exportError = bookmarks!.exportLog(logList!.last, FileType.csv, exportedFileName: "exported_route");
    if (exportError != GemError.success) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $exportError'), duration: Duration(seconds: 5)));
      }
      return;
    }
    final path = getCSVFilePath(logsDir, "exported_route");

    // Save the file to a user accessible location
    final fileData = await File(path).readAsBytes();
    await fp.FilePicker.platform.saveFile(
      dialogTitle: 'Save exported log as CSV',
      fileName: 'exported_route.csv',
      initialDirectory: "/",
      allowedExtensions: ["csv"],
      bytes: fileData,
    );
  }

  Future<void> _deletePreviousCsv() async {
    final logsDir = await getDirectoryPath("Tracks");
    final path = getCSVFilePath(logsDir, "exported_route");
    final file = File(path);
    if (file.existsSync()) {
      file.delete();
    }
  }
}
