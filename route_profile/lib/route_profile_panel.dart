// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'dart:math';

import 'package:route_profile/elevation_chart.dart';
import 'package:route_profile/section.dart';
import 'package:route_profile/utility.dart';
import 'package:gem_kit/core.dart';

import 'climb_details.dart';
import 'sliders.dart';
import 'package:flutter/material.dart' hide Route, Path;
import 'package:gem_kit/map.dart';

class RouteProfilePanel extends StatefulWidget {
  final Route route;
  final GemMapController mapController;
  final LineAreaChartController chartController;

  final VoidCallback centerOnRoute;

  // Define steepness categories
  final List<double> steepnessCategories = [
    -16.0,
    -10.0,
    -7.0,
    -4.0,
    -1.0,
    1.0,
    4.0,
    7.0,
    10.0,
    16.0,
  ];

  RouteProfilePanel({
    super.key,
    required this.route,
    required this.mapController,
    required this.chartController,
    required this.centerOnRoute,
  });

  @override
  State<RouteProfilePanel> createState() => _RouteProfilePanelState();
}

class _RouteProfilePanelState extends State<RouteProfilePanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 2,
      width: MediaQuery.of(context).size.width,
      color: Colors.grey.shade100,
      child: Scrollbar(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: LineAreaChart(
                    controller: widget.chartController,
                    points: getElevationSamples(),
                    climbSections: widget.route.terrainProfile!.climbSections,
                    onSelect: (distance) =>
                        _presentLandmarkAtDistance(distance.floor()),
                    onViewPortChanged: (leftX, rightX) {
                      final path = widget.route
                          .getPath(leftX.floor(), rightX.floor())!
                          .area;
                      _centerOnArea(path);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    LandmarkButton(
                      onTap: () {
                        widget.centerOnRoute();
                        if (widget.chartController.setCurrentHighlight !=
                            null) {
                          widget.chartController.setCurrentHighlight!(
                            0.toDouble(),
                          );
                        }
                      },
                      icon: const Icon(Icons.location_on, color: Colors.green),
                      title:
                          '${widget.route.terrainProfile!.getElevation(0).toStringAsFixed(0)} m',
                    ),
                    LandmarkButton(
                      onTap: () {
                        widget.centerOnRoute();
                        if (widget.chartController.setCurrentHighlight !=
                            null) {
                          widget.chartController.setCurrentHighlight!(
                            widget.route.totalDistance().toDouble(),
                          );
                        }
                      },
                      icon: const Icon(Icons.location_on, color: Colors.red),
                      title:
                          '${widget.route.terrainProfile!.getElevation(widget.route.totalDistance()).toStringAsFixed(0)} m',
                    ),
                    LandmarkButton(
                      onTap: () {
                        widget.centerOnRoute();
                        if (widget.chartController.setCurrentHighlight !=
                            null) {
                          widget.chartController.setCurrentHighlight!(
                            widget.route.terrainProfile!.minElevationDistance
                                .toDouble(),
                          );
                        }
                      },
                      icon: const Icon(Icons.arrow_downward),
                      title:
                          '${widget.route.terrainProfile!.minElevation.toStringAsFixed(0)} m',
                    ),
                    LandmarkButton(
                      onTap: () {
                        widget.centerOnRoute();
                        if (widget.chartController.setCurrentHighlight !=
                            null) {
                          widget.chartController.setCurrentHighlight!(
                            widget.route.terrainProfile!.maxElevationDistance
                                .toDouble(),
                          );
                        }
                      },
                      icon: const Icon(Icons.arrow_upward),
                      title:
                          '${widget.route.terrainProfile!.maxElevation.toStringAsFixed(0)} m',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClimbDetails(route: widget.route),
                const SizedBox(height: 10),
                SliderItem(
                  title: 'Surfaces',
                  sections: _getSurfaceSections(),
                  route: widget.route,
                  onSelectionChanged: (type) =>
                      _presentSurfacePaths(type as SurfaceType),
                ),
                const SizedBox(height: 10),
                SliderItem(
                  title: 'Road Types',
                  sections: _getRoadSections(),
                  route: widget.route,
                  onSelectionChanged: (type) =>
                      _presentRoadPaths(type as RoadType),
                ),
                const SizedBox(height: 10),
                SliderItem(
                  title: 'Steepness',
                  sections: _getSteepnessSections(),
                  route: widget.route,
                  onSelectionChanged: (steepness) =>
                      _presentSteepnessPaths(steepness as Steepness),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<(double, double)> getElevationSamples() {
    const maxSamples = 50000;
    const minSamples = 2;

    // Divide the route in samples.
    int countSamples = (widget.route.totalDistance() / 50).ceil();
    countSamples = min(countSamples, maxSamples);
    countSamples = max(countSamples, minSamples);

    final samples = widget.route.terrainProfile!.getElevationSamples(
      countSamples,
      0,
      widget.route.totalDistance(),
    );

    // Calculate the distance from the start of the route to every sample.
    double currentDistance = 0;
    List<(double, double)> result = [];
    for (int i = 0; i < samples.first.length; i++) {
      result.add((currentDistance, samples.first[i]));
      currentDistance += samples.second;
    }

    return result;
  }

  void _centerOnArea(RectangleGeographicArea area) {
    var br = area.bottomRight;
    var tl = area.topLeft;

    final deltaLat = tl.latitude - br.latitude;
    br.latitude = br.latitude - deltaLat;

    // Use the map controller to center on area above the panel.
    widget.mapController.centerOnArea(area);
  }

  // Divide the route in surface sections.
  List<Section> _getSurfaceSections() {
    final surfaceSections = widget.route.terrainProfile!.surfaceSections;

    List<Section> sections = [];
    Map<SurfaceType, Section> map = <SurfaceType, Section>{};

    for (int index = 0; index < surfaceSections.length; index++) {
      final type = surfaceSections[index].type;

      // Calculate the start and end distances for the current section.
      final isLast = index == surfaceSections.length - 1;
      final startDistance = surfaceSections[index].startDistanceM;
      final endDistance = isLast
          ? widget.route.totalDistance()
          : (surfaceSections[index + 1].startDistanceM);
      final length = endDistance - startDistance;

      if (!map.containsKey(type)) {
        map[type] = Section(type: type);
      }

      // Calculate the total length of the current section type.
      map[type]!.length += length;
      map[type]!.percent = map[type]!.length / widget.route.totalDistance();
    }
    sections.addAll(map.values);
    return sections;
  }

  // Find all paths of a given surface type and highlight them on the map.
  void _presentSurfacePaths(SurfaceType type) {
    List<SurfaceSection> sections =
        widget.route.terrainProfile!.surfaceSections;

    final List<Path> paths = [];
    for (int index = 0; index < sections.length; index++) {
      if (type != sections[index].type) continue;

      final isLast = index == sections.length - 1;
      final startDistance = sections[index].startDistanceM;
      final endDistance = isLast
          ? widget.route.totalDistance()
          : (sections[index + 1].startDistanceM);

      final path = widget.route.getPath(startDistance, endDistance);
      paths.add(path!);
    }
    _presentPaths(paths);
  }

  // Divide the route in road sections.
  List<Section> _getRoadSections() {
    final roadTypeSections = widget.route.terrainProfile!.roadTypeSections;

    List<Section> sections = [];
    Map<RoadType, Section> map = <RoadType, Section>{};

    for (int index = 0; index < roadTypeSections.length; index++) {
      final type = roadTypeSections[index].type;

      // Calculate the start and end distances for the current section.
      final isLast = index == roadTypeSections.length - 1;
      final startDistance = roadTypeSections[index].startDistanceM;
      final endDistance = isLast
          ? widget.route.totalDistance()
          : (roadTypeSections[index + 1].startDistanceM);
      final length = endDistance - startDistance;

      if (!map.containsKey(type)) {
        map[type] = Section(type: type);
      }

      // Calculate the total length of the current section type.
      map[type]!.length += length;
      map[type]!.percent = map[type]!.length / widget.route.totalDistance();
    }
    sections.addAll(map.values);
    return sections;
  }

  // Find all paths of a given road type and highlight them on the map.
  void _presentRoadPaths(RoadType type) {
    List<RoadTypeSection> sections =
        widget.route.terrainProfile!.roadTypeSections;

    final List<Path> paths = [];
    for (int index = 0; index < sections.length; index++) {
      if (type != sections[index].type) continue;

      final isLast = index == sections.length - 1;
      final startDistance = sections[index].startDistanceM;
      final endDistance = isLast
          ? widget.route.totalDistance()
          : (sections[index + 1].startDistanceM);

      final path = widget.route.getPath(startDistance, endDistance);
      paths.add(path!);
    }
    _presentPaths(paths);
  }

  // Divide the route in steepness sections.
  List<Section> _getSteepnessSections() {
    final steepnessSections = widget.route.terrainProfile!.getSteepSections(
      widget.steepnessCategories,
    );

    List<Section> sections = [];
    Map<Steepness, Section> map = <Steepness, Section>{};

    for (int index = 0; index < steepnessSections.length; index++) {
      final type = Steepness.values[steepnessSections[index].categ];

      // Calculate the start and end distances for the current section.
      final isLast = index == steepnessSections.length - 1;
      final startDistance = steepnessSections[index].startDistanceM;
      final endDistance = isLast
          ? widget.route.totalDistance()
          : (steepnessSections[index + 1].startDistanceM);
      final length = endDistance - startDistance;

      if (!map.containsKey(type)) {
        map[type] = Section(type: type);
      }

      // Calculate the total length of the current section type.
      map[type]!.length += length;
      map[type]!.percent = map[type]!.length / widget.route.totalDistance();
    }
    sections.addAll(map.values);

    // Sort them from descent to ascent.
    sections.sort(
      ((a, b) =>
          Steepness.values.indexOf(a.type as Steepness) -
          Steepness.values.indexOf(b.type as Steepness)),
    );
    return sections;
  }

  // Find all paths of a given steepness and highlight them on the map.
  void _presentSteepnessPaths(Steepness steepenss) {
    List<dynamic> sections = widget.route.terrainProfile!.getSteepSections(
      widget.steepnessCategories,
    );

    final List<Path> paths = [];
    for (int index = 0; index < sections.length; index++) {
      if (steepenss != Steepness.values[sections[index].categ as int]) continue;

      final isLast = index == sections.length - 1;
      final startDistance = sections[index].startDistanceM ?? 0;
      final endDistance = isLast
          ? widget.route.totalDistance()
          : (sections[index + 1].startDistanceM ?? 0);

      final path = widget.route.getPath(
        startDistance as int,
        endDistance as int,
      );
      paths.add(path!);
    }
    _presentPaths(paths);
  }

  // Highlight a path on map.
  void _presentPaths(List<Path> paths) {
    final mapPaths = widget.mapController.preferences.paths;
    mapPaths.clear();

    for (final path in paths) {
      mapPaths.add(path, colorInner: Colors.red);
    }
  }

  // Highlight the landmark at the given distance on the route.
  void _presentLandmarkAtDistance(int distance) {
    // Highlight the landmark in the chart.
    if (widget.chartController.setCurrentHighlight != null) {
      widget.chartController.setCurrentHighlight!(distance.toDouble());
    }

    // Highlight the landmark on the map.
    final landmark = Landmark();
    final coords = widget.route.getCoordinateOnRoute(distance);

    landmark.setImageFromIcon(GemIcon.searchResultsPin);
    landmark.coordinates = coords;

    widget.mapController.activateHighlight(
      [landmark],
      renderSettings: HighlightRenderSettings(
        options: {HighlightOptions.showLandmark, HighlightOptions.noFading},
      ),
    );
  }
}

class LandmarkButton extends StatelessWidget {
  final VoidCallback onTap;
  final Icon icon;
  final String title;
  const LandmarkButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            height: 65,
            width: 65,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: icon,
          ),
        ),
        Text(title),
      ],
    );
  }
}
