// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:flutter/material.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:gem_kit/sense.dart';

import 'package:recorder_bookmarks/recorder_bookmarks_page.dart';
import 'package:recorder_bookmarks/utils.dart';

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
      title: 'Recorder Bookmarks',
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
  RecorderBookmarks? _recorderBookmarks;

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
          'Recorder Bookmarks',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (_recorderBookmarks == null)
            IconButton(
              onPressed: _onImportButtonPressed,
              icon: Icon(Icons.upload, color: Colors.white),
            ),
        ],
      ),
      body: Stack(
        children: [
          GemMap(key: ValueKey("GemMap"), appAuthorization: projectApiToken),
          if (_recorderBookmarks != null)
            Positioned(
              bottom: 15,
              left: 0,
              right: 0,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) {
                        return RecorderBookmarksPage(
                          recorderBookmarks: _recorderBookmarks!,
                        );
                      },
                    ),
                  );
                },
                child: Text("Recorder Logs"),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onImportButtonPressed() async {
    // Upload log files from assets folder to phone's memory into Tracks directory
    copyLogToAppDocsDir("2025-04-29_12-42-26_700.gm");
    copyLogToAppDocsDir("2025-04-29_12-59-52_568.gm");

    // Get Tracks directory path
    final logsDirectory = await getDirectoryPath("Tracks");

    // Create a RecorderBookmarks instance based on Tracks directory location
    final recorderBookmarks = RecorderBookmarks.create(logsDirectory);

    if (recorderBookmarks == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error while creating RecorderBookmarks'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      _recorderBookmarks = recorderBookmarks;
    });

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully imported logs.'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
