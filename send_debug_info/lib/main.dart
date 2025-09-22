// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');

void main() async {
  // Turn on logging
  Debug.logCallObjectMethod = false;
  Debug.logCreateObject = true;
  Debug.logLevel = GemLoggingLevel.all;
  Debug.logListenerMethod = true;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Send Debug Info',
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
        title: const Text(
          'Send Debug Info',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _shareLogs,
            icon: const Icon(Icons.share, color: Colors.white),
          ),
        ],
      ),
      body: GemMap(
        key: ValueKey("GemMap"),
        appAuthorization: projectApiToken,
        onMapCreated: (ctrl) async {
          await Debug.setSdkDumpLevel(GemDumpSdkLevel.verbose);

          // Redirect Dart SDK logs to the SDK dump log file
          final dartSdkLogger = Logger('GemSdkLogger');
          dartSdkLogger.onRecord.listen((record) {
            Debug.log(
                level: GemDumpSdkLevel.verbose,
                message: '${record.time} ${record.message}');
          });
        },
      ),
    );
  }

  Future<void> _shareLogs() async {
    // Get the path to the SDK log dump file
    final logPath = await Debug.getSdkLogDumpPath();

    await SharePlus.instance.share(ShareParams(files: [XFile(logPath)]));
  }
}
