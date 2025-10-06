// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:flutter/material.dart';
import 'package:magiclane_maps_flutter/map.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

class DepartureTimesPanel extends StatelessWidget {
  final List<PTStopTime> stopTimes;
  final DateTime localTime;
  final VoidCallback onCloseTap;
  const DepartureTimesPanel({
    super.key,
    required this.stopTimes,
    required this.localTime,
    required this.onCloseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // the scrollable list with dividers
        Expanded(
          child: Container(
            color: Colors.white,
            child: ListView.separated(
              itemCount: stopTimes.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: DepartureTimesListItem(
                  stop: stopTimes[index],
                  localCurrentTime: localTime,
                ),
              ),
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 1,
                indent: 16, // optional: inset the divider from the left
                endIndent: 16, // optional: inset the divider from the right
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DepartureTimesListItem extends StatelessWidget {
  final PTStopTime stop;
  final DateTime localCurrentTime;
  const DepartureTimesListItem({
    super.key,
    required this.stop,
    required this.localCurrentTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stop.stopName, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (stop.departureTime != null)
                Text(
                  stop.departureTime!.isAfter(localCurrentTime)
                      ? "Scheduled"
                      : "Departed",
                ),
            ],
          ),
        ),
        SizedBox(width: 8),
        Text(
          stop.departureTime != null
              ? DateFormat('H:mm').format(stop.departureTime!)
              : '-',
        ),
      ],
    );
  }
}
