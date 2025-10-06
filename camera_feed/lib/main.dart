// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:camera_feed/utils.dart';
import 'package:flutter/material.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/sense.dart';
import 'package:permission_handler/permission_handler.dart';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GemKit.initialize(appAuthorization: projectApiToken);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Camera feed',
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
  Recorder? _recorder;
  DataSource? _ds;
  GemCameraPlayerController? _cameraPlayerController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    GemKit.release();
    super.dispose();
  }

  void _watchPlayerStatus() {
    _cameraPlayerController?.addListener(() {
      if (_cameraPlayerController!.status == GemCameraPlayerStatus.playing) {
        setState(() {}); // Size likely available now
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple[900],
          title: const Text('Camera feed', style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              icon: Icon(
                Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: () async {
                if (_cameraPlayerController == null) {
                  _ds = DataSource.createLiveDataSource()!;

                  _ds!.start();

                  _recorder = Recorder.create(RecorderConfiguration(
                    logsDir: await getDirectoryPath('Tracks'),
                    dataSource: _ds!,
                    videoQuality: Resolution.hd720p,
                    recordedTypes: [DataType.position, DataType.camera],
                    transportMode: RecordingTransportMode.car,
                  ));

                  await _recorder!.startRecording();

                  _cameraPlayerController = GemCameraPlayerController(dataSource: _ds!);

                  _watchPlayerStatus();

                  setState(() {});
                }
              },
            ),
            IconButton(
              icon: Icon(
                Icons.stop,
                color: Colors.white,
              ),
              onPressed: () async {
                await _recorder!.stopRecording();

                _cameraPlayerController?.dispose();
                _ds?.stop();
                _cameraPlayerController = null;
                _ds = null;
                setState(() {});
              },
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
            Positioned(
              top: 10,
              left: 10,
              child: SafeArea(
                top: true,
                left: true,
                child: Builder(
                  builder: (context) {
                    final controller = _cameraPlayerController;

                    if (controller == null ||
                        controller.isDisposed ||
                        controller.status != GemCameraPlayerStatus.playing ||
                        controller.size == null) {
                      return const SizedBox(
                        width: 150,
                        height: 150,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    return SizedBox(
                      width: 200,
                      child: AspectRatio(
                        aspectRatio: controller.size!.$1.toDouble() / controller.size!.$2.toDouble(),
                        child: GemCameraPlayer(
                          controller: controller,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // The callback for when map is ready to use.
  void _onMapCreated(GemMapController controller) async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.locationWhenInUse,
    ].request();
  }
}
