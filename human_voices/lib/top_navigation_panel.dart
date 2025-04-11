// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/core.dart';
import 'package:gem_kit/navigation.dart';

import 'utility.dart';

import 'package:flutter/material.dart';

class NavigationInstructionPanel extends StatelessWidget {
  final NavigationInstruction instruction;

  const NavigationInstructionPanel({super.key, required this.instruction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 20,
      height: MediaQuery.of(context).size.height * 0.2,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            width: 100,
            child:
                instruction.nextTurnDetails.abstractGeometryImg.isValid
                    ? Image.memory(
                      instruction.nextTurnDetails.abstractGeometryImg
                          .getRenderableImageBytes(
                            size: Size(200, 200),
                            format: ImageFileFormat.png,
                          )!,
                      gaplessPlayback: true,
                    )
                    : const SizedBox(), // Empty widget
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width - 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  instruction.getFormattedDistanceToNextTurn(),
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  instruction.nextStreetName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
