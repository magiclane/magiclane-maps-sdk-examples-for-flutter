// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:flutter/material.dart';

class BottomSpeedLimitPanel extends StatelessWidget {
  final int speed;

  const BottomSpeedLimitPanel({super.key, required this.speed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      width: MediaQuery.of(context).size.width - 20,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Text(
            "Current speed limit: $speed km/h",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
