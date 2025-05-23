// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:flutter/material.dart';
import 'package:gem_kit/map.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:public_transit_stop_schedule/departure_times_panel.dart';
import 'package:public_transit_stop_schedule/utils.dart';

class PublicTransitStopPanel extends StatefulWidget {
  final PTStopInfo ptStopInfo;
  final DateTime localTime;
  final VoidCallback onCloseTap;

  const PublicTransitStopPanel({
    super.key,
    required this.ptStopInfo,
    required this.localTime,
    required this.onCloseTap,
  });

  @override
  State<PublicTransitStopPanel> createState() => _PublicTransitStopPanelState();
}

class _PublicTransitStopPanelState extends State<PublicTransitStopPanel> {
  PTTrip? _selectedTrip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_selectedTrip != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _selectedTrip = null),
                )
              else
                const SizedBox(width: 48),
              Text(
                _selectedTrip == null
                    ? 'Select a Trip'
                    : 'Stops for ${_selectedTrip!.route.routeShortName}',
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onCloseTap,
              ),
            ],
          ),
        ),

        // Body: either list of trips or list of stops
        Expanded(
          child: Container(
            color: Colors.white,
            child: _selectedTrip == null
                ? ListView.separated(
                    itemCount: widget.ptStopInfo.trips.length,
                    itemBuilder: (context, index) {
                      final trip = widget.ptStopInfo.trips[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: PTLineListItem(
                          localCurrentTime: widget.localTime,
                          ptTrip: trip,
                          onTap: () {
                            setState(() {
                              _selectedTrip = trip;
                            });
                          },
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                  )
                : DepartureTimesPanel(
                    stopTimes: _selectedTrip!.stopTimes,
                    localTime: widget.localTime,
                    onCloseTap: widget.onCloseTap,
                  ),
          ),
        ),
      ],
    );
  }
}

class PTLineListItem extends StatelessWidget {
  final PTTrip ptTrip;
  final DateTime localCurrentTime;
  final VoidCallback onTap;

  const PTLineListItem({
    super.key,
    required this.ptTrip,
    required this.localCurrentTime,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(getTransportIcon(ptTrip.route.routeType)),
              SizedBox(width: 7.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 15.0,
                    ),
                    decoration: BoxDecoration(
                      color: ptTrip.route.routeColor,
                      borderRadius: BorderRadius.circular(
                        14.0,
                      ), // adjust radius as you like
                    ),
                    child: Text(
                      ptTrip.route.routeShortName ?? "None",
                      style: TextStyle(
                        color: ptTrip.route.routeTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    ptTrip.route.heading ?? ptTrip.route.routeLongName ?? "Nan",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    ptTrip.departureTime != null
                        ? 'Scheduled • ${DateFormat('H:mm').format(ptTrip.departureTime!)}'
                        : 'Scheduled • ',
                  ),
                ],
              ),
            ],
          ),
          Text(calculateTimeDifference(localCurrentTime, ptTrip)),
        ],
      ),
    );
  }
}
