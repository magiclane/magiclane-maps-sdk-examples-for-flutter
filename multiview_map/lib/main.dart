// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'package:flutter/material.dart';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Multiview Map',
      debugShowCheckedModeBanner: false,
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
  int _mapViewsCount = 0;

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
          'Multiview Map',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _addViewButtonPressed,
            icon: Icon(
              Icons.add,
              color: (_mapViewsCount < 4) ? Colors.white : Colors.grey,
            ),
          ),
          IconButton(
            onPressed: _removeViewButtonPressed,
            icon: Icon(
              Icons.remove,
              color: (_mapViewsCount != 0) ? Colors.white : Colors.grey,
            ),
          ),
        ],
      ),
      // Arrange MapViews in a grid with fixed number on elements on row
      body: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemCount: _mapViewsCount,
        itemBuilder: (context, index) {
          return Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.grey,
                  offset: Offset(0, -2),
                  spreadRadius: 1,
                  blurRadius: 2,
                ),
              ],
            ),
            margin: const EdgeInsets.all(5),
            child: const GemMap(
              key: ValueKey("GemMap"),
              appAuthorization: projectApiToken,
            ),
          );
        },
      ),
    );
  }

  // Add one more view on button press
  void _addViewButtonPressed() => setState(() {
        if (_mapViewsCount < 4) {
          _mapViewsCount += 1;
        }
      });

  void _removeViewButtonPressed() => setState(() {
        if (_mapViewsCount > 0) {
          _mapViewsCount -= 1;
        }
      });
}
