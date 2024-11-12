// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'package:flutter/material.dart';
import 'package:gem_kit/sense.dart';
import 'package:speed_watcher/utility.dart';

class SpeedIndicator extends StatefulWidget {
  const SpeedIndicator({super.key});

  @override
  State<SpeedIndicator> createState() => _SpeedIndicatorState();
}

class _SpeedIndicatorState extends State<SpeedIndicator> {
  double _currentSpeed = 0;
  double _speedLimit = 0;

  @override
  void initState() {
    // Listen to the current position to detect the current speed and the speed limit.
    PositionService.instance.addImprovedPositionListener((position) {
      if (mounted) {
        setState(() {
          _currentSpeed = position.speed;
          _speedLimit = position.speedLimit;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: 200,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Current speed:'),
          Text('${mpsToKmph(_currentSpeed)} km/h'),
          const SizedBox(height: 10),
          const Text('Speed limit:'),
          Text('${mpsToKmph(_speedLimit)} km/h'),
        ],
      ),
    );
  }
}
