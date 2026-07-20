// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.
//
// Marker clustering example.
//
// Renders a large set of campsites from a bundled GeoJSON onto a Magic Lane
// map: native clustering into count "pill" bubbles at low zoom, green/red
// per-type pins once the clusters break up, tap a cluster to zoom in and split
// it, tap a pin for an info sheet.
//
// Markers are drawn by the SDK itself (two overlapping collections), so they
// stay perfectly locked to the map during pan/zoom — the reason we use native
// rendering rather than a Flutter-widget overlay. Two collections are needed
// because a marker that carries per-marker render settings suppresses the SDK's
// cluster count, so the count (cluster layer) and the coloured pins (detail
// layer) come from separate collections.

import 'dart:math';

import 'package:flutter/material.dart' hide Route;
import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';

import 'campsite.dart';
import 'map_zoom_converter.dart';
import 'marker_assets.dart';

const projectApiToken = String.fromEnvironment('YOUR_API_TOKEN_HERE');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Marker Clustering',
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Continental-US start view, so the whole campground spread is visible.
  static final _usCenter = Coordinates(latitude: 39.5, longitude: -98.35);
  static const _usZoom = 9;

  // Cluster (group) markers up to app-zoom 6; break into pins above it.
  static final _clusterZoom = MapZoomConverter.toMagicLaneZoom(6.0);

  static const _collectionName = 'campsites';

  GemMapController? _controller;
  MarkerAssets? _assets;
  bool _loading = false;
  bool _loaded = false;
  double? _progress; // null → indeterminate
  String _status = '';
  Campsite? _selected;

  // How many markers to build between UI yields. Keeps the progress bar and
  // spinner animating instead of the whole load blocking the main thread.
  static const _buildChunk = 2000;

  void _report(double? progress, String status) {
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _status = status;
    });
  }

  @override
  void dispose() {
    GemKit.release();
    super.dispose();
  }

  Future<void> _onMapCreated(GemMapController controller) async {
    _controller = controller;

    // Enable the (invisible) cursor so tap → marker selection works.
    controller.preferences.enableCursor = true;
    controller.preferences.enableCursorRender = false;

    controller.centerOnCoordinates(_usCenter, zoomLevel: _usZoom);
    controller.registerOnTouch(_onTouch);
  }

  /// Loads the artwork + GeoJSON and renders the campsite layers. Triggered by
  /// the "Load campsites" button rather than at startup, so the map opens empty.
  Future<void> _loadCampsites() async {
    if (_controller == null || _loading || _loaded) return;
    setState(() {
      _loading = true;
      _progress = null; // indeterminate while the file is read + parsed
      _status = 'Reading campsite data…';
    });

    // Load artwork and the GeoJSON in parallel (the parse runs on a background
    // isolate, so the UI stays responsive here).
    final results = await Future.wait([
      MarkerAssets.load(),
      CampsiteLoader.loadFromAssets(),
    ]);
    _assets = results[0] as MarkerAssets;
    final campsites = results[1] as List<Campsite>;

    await _renderCampsites(campsites);
    if (mounted) {
      setState(() {
        _loading = false;
        _loaded = true;
      });
    }
  }

  /// Two overlapping SDK-drawn collections:
  ///
  ///   1. CLUSTER layer — one marker per campsite, collection-level settings
  ///      only (no per-marker settings). The SDK groups them into density
  ///      "pill" bubbles and paints the white COUNT on them. Loose (ungrouped)
  ///      markers draw a transparent image.
  ///   2. DETAIL layer — one coloured green/red pin per campsite via `addList`
  ///      (the SDK's optimised bulk path). Its group images are transparent, so
  ///      it shows nothing while clustered and only its pins once clusters split.
  ///
  /// Both group at the same zoom, so a pill never sits on top of a pin.
  Future<void> _renderCampsites(List<Campsite> campsites) async {
    final controller = _controller;
    final assets = _assets;
    if (controller == null || assets == null) return;

    final total = campsites.length;

    // 1) Cluster layer — count-bearing pills. No per-marker settings.
    // Built in chunks with a yield between them so the progress bar animates
    // (this loop is otherwise heavy enough to freeze the UI thread).
    final clusterCollection = MarkerCollection(
      markerType: MarkerType.point,
      name: '$_collectionName-clustered',
    );
    for (var i = 0; i < total; i++) {
      final c = campsites[i];
      clusterCollection.add(
        Marker.fromCoords(
            [Coordinates(latitude: c.latitude, longitude: c.longitude)]),
      );
      if (i % _buildChunk == 0) {
        _report(0.05 + 0.40 * (i / total), 'Building clusters… $i / $total');
        await Future<void>.delayed(Duration.zero);
      }
    }

    final clusterSettings = MarkerCollectionRenderSettings(
      pointsGroupingZoomLevel: _clusterZoom,
      buildPointsGroupConfig: true,
      // Density "pill" bubbles, widening with the digit count. Tiers:
      // ≤200 low, ≤4000 medium, else high.
      lowDensityPointsGroupImage: assets.lowPill,
      mediumDensityPointsGroupImage: assets.mediumPill,
      highDensityPointsGroupImage: assets.highPill,
      lowDensityPointsGroupMaxCount: 200,
      mediumDensityPointsGroupMaxCount: 4000,
      labelGroupTextSize: 2.7,
      labelingMode: const {
        MarkerLabelingMode.groupLabelVisible,
        MarkerLabelingMode.groupCenter,
      },
    );
    // White count on the dark-green pill. Two things matter here:
    //   • labelGroupTextColor defaults to TRANSPARENT (alpha 0) — set it opaque
    //     or the count is invisible.
    //   • do NOT set labelTextSize = 0: zeroing the item-label size also breaks
    //     the group-count colour (it renders black instead of the set colour).
    clusterSettings.labelGroupTextColor = const Color(0xFFFFFFFF);
    // Size the pill (mm) so the count sits inside it — pairs with the 2.7 mm
    // group text (imageSize 5.8 / text 2.7).
    clusterSettings.imageSize = 5.8;
    clusterSettings.image = assets.transparent; // loose singles invisible
    _report(0.45, 'Placing clusters on map…');
    await Future<void>.delayed(Duration.zero);
    controller.preferences.markers
        .add(clusterCollection, settings: clusterSettings);

    // 2) Detail layer — coloured pins via the optimised addList bulk path.
    // Built in chunks (same reason as above) before the single bulk add.
    final markers = <MarkerWithRenderSettings>[];
    for (var i = 0; i < total; i++) {
      final c = campsites[i];
      markers.add(
        MarkerWithRenderSettings(
          MarkerJson(
            coords: [Coordinates(latitude: c.latitude, longitude: c.longitude)],
            name: c.markerName,
          ),
          MarkerRenderSettings(
            image: assets.pinFor(bookable: c.isBookable),
            imageSize: 6.0, // mm
            labelingMode: const {MarkerLabelingMode.iconBottomCenter},
          ),
        ),
      );
      if (i % _buildChunk == 0) {
        _report(0.45 + 0.45 * (i / total), 'Building pins… $i / $total');
        await Future<void>.delayed(Duration.zero);
      }
    }

    final detailSettings = MarkerCollectionRenderSettings(
      pointsGroupingZoomLevel: _clusterZoom,
      // Transparent group images → the detail layer shows nothing while
      // clustered; the cluster layer's pills+counts show instead.
      lowDensityPointsGroupImage: assets.transparent,
      mediumDensityPointsGroupImage: assets.transparent,
      highDensityPointsGroupImage: assets.transparent,
      labelGroupTextSize: 0,
      // No group label on this layer (its default would draw a second, black
      // count over the cluster layer's white one).
      labelingMode: const {MarkerLabelingMode.iconBottomCenter},
    );

    _report(0.95, 'Rendering ${markers.length} pins…');
    await Future<void>.delayed(Duration.zero);
    await controller.preferences.markers.addList(
      list: markers,
      settings: detailSettings,
      name: '$_collectionName-detail',
    );
    _report(1.0, 'Done');
  }

  // ---- Tap handling -------------------------------------------------------

  Future<void> _onTouch(Point<int> pos) async {
    final controller = _controller;
    if (controller == null) return;

    // Setting the cursor position is async and must be awaited before reading
    // the selection, otherwise the match list comes back empty.
    await controller.setCursorScreenPosition(pos);
    final matches = controller.cursorSelectionMarkers();
    if (matches.isEmpty) return;

    // A cluster tap is a CoordinateGroup match → zoom in toward the tap to break
    // the cluster apart.
    final isCluster =
        matches.any((m) => m.type == MarkerMatchType.coordinateGroup);
    if (isCluster) {
      final target = (controller.zoomLevel + 12).clamp(0, 90).toInt();
      controller.centerOnCoordinates(
        controller.transformScreenToWgs(pos),
        zoomLevel: target,
        animation: GemAnimation(type: AnimationType.linear, duration: 500),
      );
      return;
    }

    // Otherwise a single campsite → pick the match carrying our JSON metadata,
    // centre on it, and show its info sheet.
    MarkerMatch chosen = matches.first;
    for (final m in matches) {
      if (Campsite.decodeMarkerName(m.marker.name)['id'] != null) {
        chosen = m;
        break;
      }
    }
    final marker = chosen.marker;
    final info = Campsite.decodeMarkerName(marker.name);
    final coords = marker.getCoordinates();
    if (coords.isEmpty) return;
    final point = coords.first;

    controller.centerOnCoordinates(
      point,
      animation: GemAnimation(type: AnimationType.linear, duration: 400),
    );

    setState(() {
      _selected = Campsite(
        id: (info['id'] as num?)?.toInt() ?? marker.id,
        name: (info['name'] as String?) ?? '',
        country: null,
        reviewScore: null,
        stars: null,
        isBookable: info['bookable'] == true,
        latitude: point.latitude,
        longitude: point.longitude,
      );
    });
  }

  // ---- UI -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GemMap(
            key: const ValueKey('GemMap'),
            appAuthorization: projectApiToken,
            onMapCreated: _onMapCreated,
          ),
          if (_loading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _LoadingChip(progress: _progress, label: _status),
                ),
              ),
            ),
          if (!_loaded && !_loading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: SafeArea(
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _loadCampsites,
                    icon: const Icon(Icons.place_outlined),
                    label: const Text('Load campsites'),
                  ),
                ),
              ),
            ),
          if (_selected != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: SafeArea(
                child: _InfoSheet(
                  campsite: _selected!,
                  onClose: () => setState(() => _selected = null),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoadingChip extends StatelessWidget {
  const _LoadingChip({required this.progress, required this.label});

  /// null → indeterminate (bar animates but shows no fixed %).
  final double? progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final pct = progress == null
        ? null
        : '${(progress!.clamp(0.0, 1.0) * 100).round()}%';
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(pct == null ? label : '$label  ·  $pct'),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 240,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(value: progress, minHeight: 5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  const _InfoSheet({required this.campsite, required this.onClose});

  final Campsite campsite;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final title =
        campsite.name.isNotEmpty ? campsite.name : 'Campsite #${campsite.id}';
    final coord =
        '${campsite.latitude.toStringAsFixed(5)}, ${campsite.longitude.toStringAsFixed(5)}';

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 4, right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // bookable = red, info-only = green.
                color: campsite.isBookable
                    ? const Color(0xFFDD3137)
                    : const Color(0xFF007228),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(campsite.isBookable ? 'Bookable' : 'Info only',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  const SizedBox(height: 2),
                  Text(coord,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
