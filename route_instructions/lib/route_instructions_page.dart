// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:magiclane_maps_flutter/core.dart';

import 'utils.dart';

import 'package:flutter/material.dart';

class RouteInstructionsPage extends StatefulWidget {
  final List<RouteInstruction> instructionList;

  const RouteInstructionsPage({super.key, required this.instructionList});

  @override
  State<RouteInstructionsPage> createState() => _RouteInstructionsState();
}

class _RouteInstructionsState extends State<RouteInstructionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text(
          "Route Instructions",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple[900],
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: widget.instructionList.length,
        separatorBuilder: (context, index) =>
            const Divider(indent: 50, height: 0),
        itemBuilder: (contex, index) {
          final instruction = widget.instructionList.elementAt(index);
          return InstructionsItem(instruction: instruction);
        },
      ),
    );
  }
}

class InstructionsItem extends StatefulWidget {
  final RouteInstruction instruction;
  const InstructionsItem({super.key, required this.instruction});

  @override
  State<InstructionsItem> createState() => _InstructionsItemState();
}

class _InstructionsItemState extends State<InstructionsItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        width: 50,
        child: widget.instruction.turnImg.isValid
            ? Image.memory(
                widget.instruction.turnDetails.getAbstractGeometryImage(
                  renderSettings: AbstractGeometryImageRenderSettings(),
                  size: Size(100, 100),
                )!,
              )
            : SizedBox(),
      ),
      title: Text(
        widget.instruction.turnInstruction,
        overflow: TextOverflow.fade,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        maxLines: 2,
      ),
      subtitle: Text(
        widget.instruction.followRoadInstruction,
        overflow: TextOverflow.fade,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        maxLines: 2,
      ),
      trailing: Text(
        getFormattedDistanceUntilInstruction(widget.instruction),
        overflow: TextOverflow.fade,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
