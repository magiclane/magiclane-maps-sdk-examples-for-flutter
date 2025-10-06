// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:datasource_listeners/device_sensors_data.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';

import 'package:flutter/material.dart' hide Animation, Route, Orientation;
import 'package:permission_handler/permission_handler.dart';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, title: 'Datasource Listeners', home: MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool hasGrantedPermissions = false;
  @override
  void dispose() {
    GemKit.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Datasource Listeners", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple[900],
        actions: [
          IconButton(
            onPressed: () async {
              await _requestPermissions();
              if (!context.mounted) return;
              Navigator.push(context, MaterialPageRoute<void>(builder: (context) => const DeviceSensorsDataPage()));
            },
            icon: const Icon(Icons.article_outlined, color: Colors.white),
          ),
        ],
      ),
      body: GemMap(key: ValueKey("GemMap"), appAuthorization: projectApiToken),
      resizeToAvoidBottomInset: false,
    );
  }

  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.location,
      Permission.locationAlways,
      Permission.locationWhenInUse,
      Permission.sensors,
      Permission.camera,
    ];
    for (final permission in permissions) {
      final status = await permission.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        await permission.request();
      }
    }
  }
}
