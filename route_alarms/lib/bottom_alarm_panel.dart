// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'dart:typed_data';

import 'package:flutter/material.dart';

class BottomAlarmPanel extends StatelessWidget {
  final String remainingDistance;
  final Uint8List? image;

  const BottomAlarmPanel({
    super.key,
    required this.remainingDistance,
    required this.image,
  });

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
          image != null
              ? Image.memory(
                  image!,
                  width: 50,
                  height: 50,
                  gaplessPlayback: true,
                )
              : SizedBox(),
          const SizedBox(width: 20),
          Text(
            "$remainingDistance m",
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
