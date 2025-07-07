// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'dart:async';

import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';

import 'package:flutter/material.dart' hide Animation;
import 'package:gem_kit/projections.dart';
import 'package:projections/projections_panel.dart';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Projections',
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
  late GemMapController _mapController;

  WGS84Projection? _wgsProjection;
  MGRSProjection? _mgrsProjection;
  UTMProjection? _utmProjection;
  LAMProjection? _lamProjection;
  W3WProjection? _w3wProjection;
  GKProjection? _gkProjection;
  BNGProjection? _bngProjection;

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
          'Projections',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        alignment: AlignmentDirectional.bottomStart,
        children: [
          GemMap(
            key: ValueKey("GemMap"),
            onMapCreated: _onMapCreated,
            appAuthorization: projectApiToken,
          ),
          if (_wgsProjection != null)
            ProjectionsPanel(
              wgsProjection: _wgsProjection,
              mgrsProjection: _mgrsProjection,
              utmProjection: _utmProjection,
              lamProjection: _lamProjection,
              w3wProjection: _w3wProjection,
              gkProjection: _gkProjection,
              bngProjection: _bngProjection,
              onClose: () {
                setState(() {
                  _wgsProjection = null;
                  _mgrsProjection = null;
                  _utmProjection = null;
                  _lamProjection = null;
                  _w3wProjection = null;
                  _gkProjection = null;
                  _bngProjection = null;
                });
              },
            ),
        ],
      ),
    );
  }

  // The callback for when map is ready to use.
  void _onMapCreated(GemMapController controller) async {
    // Save controller for further usage.
    _mapController = controller;

    _mapController.centerOnCoordinates(
      Coordinates(latitude: 45.472358, longitude: 9.184945),
      zoomLevel: 80,
    );

    // Enable cursor to render on screen
    _mapController.preferences.enableCursor = true;
    _mapController.preferences.enableCursorRender = true;

    // Register touch callback to set cursor to tapped position
    _mapController.registerTouchCallback((point) async {
      // Transform the screen point to Coordinates
      final coords = _mapController.transformScreenToWgs(point);

      // Update cursor position on the map
      _mapController.setCursorScreenPosition(point);

      // Build WGS84 projection from Coordinates
      final wgsProjection = WGS84Projection(coords);

      final utmProjection =
          await convertProjection(wgsProjection, ProjectionType.utm)
              as UTMProjection?;
      final mgrsProjection =
          await convertProjection(wgsProjection, ProjectionType.mgrs)
              as MGRSProjection?;
      final lamProjection =
          await convertProjection(wgsProjection, ProjectionType.lam)
              as LAMProjection?;
      final w3wProjection =
          await convertProjection(wgsProjection, ProjectionType.w3w)
              as W3WProjection?;
      final gkProjection =
          await convertProjection(wgsProjection, ProjectionType.gk)
              as GKProjection?;
      final bngProjection =
          await convertProjection(wgsProjection, ProjectionType.bng)
              as BNGProjection?;

      setState(() {
        _wgsProjection = wgsProjection;
        _utmProjection = utmProjection;
        _mgrsProjection = mgrsProjection;
        _lamProjection = lamProjection;
        _w3wProjection = w3wProjection;
        _gkProjection = gkProjection;
        _bngProjection = bngProjection;
      });
    });
  }

  Future<Projection?> convertProjection(
      Projection projection, ProjectionType type) async {
    final completer = Completer<Projection?>();

    ProjectionService.convert(
        from: projection,
        toType: type,
        onCompleteCallback: (err, convertedProjection) {
          if (err != GemError.success) {
            completer.complete(null);
          } else {
            completer.complete(convertedProjection);
          }
        });

    return await completer.future;
  }
}
