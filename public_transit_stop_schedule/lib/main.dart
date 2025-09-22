// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:flutter/material.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:public_transit_stop_schedule/public_transit_stop_panel.dart';
import 'package:public_transit_stop_schedule/utils.dart';

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
      title: 'Public Transit Stops',
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
  PTStopInfo? _selectedPTStop;
  Coordinates? _selectedPTStopCoords;
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
          'Public Transit Stops',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          GemMap(
            key: ValueKey("GemMap"),
            appAuthorization: projectApiToken,
            onMapCreated: (controller) => _onMapCreated(controller),
          ),
          if (_selectedPTStop != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: FutureBuilder(
                  future: getLocalTime(_selectedPTStopCoords!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container();
                    }
                    return PublicTransitStopPanel(
                      ptStopInfo: _selectedPTStop!,
                      localTime: snapshot.data!,
                      onCloseTap: () => setState(() {
                        _selectedPTStop = null;
                        _selectedPTStopCoords = null;
                      }),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onMapCreated(GemMapController controller) async {
    // Save controller for further usage.
    _mapController = controller;

    _mapController.registerOnLongPress((pos) async {
      // Update the cursor screen position
      await _mapController.setCursorScreenPosition(pos);

      // Get the public transit overlay items at that position
      final items = _mapController.cursorSelectionOverlayItemsByType(
        CommonOverlayId.publicTransport,
      );
      final coords = _mapController.transformScreenToWgs(pos);

      for (final OverlayItem item in items) {
        // Get the stop information
        final ptStopInfo = await item.getPTStopInfo();
        if (ptStopInfo != null) {
          setState(() {
            _selectedPTStop = ptStopInfo;
            _selectedPTStopCoords = coords;
          });
        }
      }
    });
  }
}
