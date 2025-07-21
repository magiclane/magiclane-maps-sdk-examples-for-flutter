// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'dart:async';

import 'package:another_xlider/models/handler.dart';
import 'package:another_xlider/models/trackbar.dart';
import 'package:route_profile/section.dart';

import 'package:flutter/material.dart' hide Route, Path;
import 'package:gem_kit/core.dart';

import 'package:another_xlider/another_xlider.dart';

import 'utility.dart';

class SliderItem extends StatefulWidget {
  final String title;
  final Route route;
  final List<Section> sections;
  final void Function(Enum) onSelectionChanged;

  const SliderItem({
    super.key,
    required this.route,
    required this.onSelectionChanged,
    required this.sections,
    required this.title,
  });

  @override
  State<SliderItem> createState() => _SliderItemState();
}

class _SliderItemState extends State<SliderItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title),
          SlidingSection(
            sections: widget.sections,
            distance: widget.route.totalDistance(),
            onSelectionChanged: (section) {
              widget.onSelectionChanged(section.type);
            },
          ),
        ],
      ),
    );
  }
}

class SlidingSection extends StatefulWidget {
  final List<Section> sections;
  final int distance;
  final void Function(Section) onSelectionChanged;

  const SlidingSection({
    super.key,
    required this.sections,
    required this.distance,
    required this.onSelectionChanged,
  });

  @override
  State<SlidingSection> createState() => _SlidingSectionState();
}

class _SlidingSectionState extends State<SlidingSection> {
  late Section _selectedSection;
  late double _selectedValue;

  Timer? _debounce;

  @override
  void initState() {
    _selectedSection = widget.sections.first;
    _selectedValue = 0.0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            SizedBox(
              height: 40,
              child: Row(
                children: List.generate(widget.sections.length, (index) {
                  final sectionWidth =
                      (MediaQuery.of(context).size.width - 40) *
                      widget.sections[index].percent;
                  return Container(
                    width: sectionWidth,
                    color: getColorBasedOnType(widget.sections[index].type),
                  );
                }),
              ),
            ),
            SizedBox(
              height: 40,
              child: FlutterSlider(
                values: [_selectedValue],
                max: widget.distance.toDouble(),
                min: 0,
                onDragging: (handlerIndex, lowerValue, upperValue) {
                  final interval = findIntervalLimits(lowerValue as double);
                  if (interval.isEmpty) return;
                  _onSelectionChanged(interval.first, interval.last);
                  _getSelectedSection(lowerValue);
                },
                handlerWidth: 5,
                handlerHeight: 40,
                handler: FlutterSliderHandler(
                  decoration: const BoxDecoration(),
                  child: Container(color: Colors.red),
                ),
                trackBar: const FlutterSliderTrackBar(
                  activeTrackBar: BoxDecoration(color: Colors.transparent),
                  inactiveTrackBar: BoxDecoration(color: Colors.transparent),
                  activeTrackBarHeight: 5,
                ),
              ),
            ),
          ],
        ),
        Text(
          '${_selectedSection.type.name}: ${convertDistance(_selectedSection.percent * widget.distance)} (${(_selectedSection.percent * 100).toStringAsFixed(1)}%)',
        ),
      ],
    );
  }

  // Calculate the start and the end of an interval on the route.
  List<double> findIntervalLimits(double value) {
    double prevStart = 0;
    final dist = widget.distance;

    for (final s in widget.sections) {
      final sectionLength = s.percent * dist;
      if (value >= prevStart && value <= prevStart + sectionLength) {
        if (prevStart + sectionLength > dist) {
          return [prevStart, dist.toDouble()];
        }
        return [prevStart, prevStart + sectionLength];
      }
      prevStart += sectionLength;
    }

    return [];
  }

  // Calculate the percent of the selected section found in the current route.
  int findPercentIndex(double val) {
    List<double> accumulatedPercentages = [];
    double accumulatedPercentage = 0;
    for (final section in widget.sections) {
      accumulatedPercentage += section.percent;
      accumulatedPercentages.add(accumulatedPercentage);
    }

    for (var i = 0; i < accumulatedPercentages.length; i++) {
      if (val <= accumulatedPercentages[i] * widget.distance) {
        return i;
      }
    }

    return widget.sections.length - 1;
  }

  void _onSelectionChanged(double start, double dest) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      double total = 0;
      for (final section in widget.sections) {
        total += section.length;
        final diff = (total - dest).abs();
        if (diff < 0.01) {
          widget.onSelectionChanged(section);
          return;
        }
      }
    });
  }

  // Set the selected section.
  void _getSelectedSection(double val) {
    final index = findPercentIndex(val);

    setState(() {
      _selectedSection = widget.sections[index];
      _selectedValue = val;
    });
  }
}
