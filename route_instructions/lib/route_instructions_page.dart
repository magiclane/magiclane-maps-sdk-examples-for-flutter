// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'package:gem_kit/core.dart';
import 'package:gem_kit/routing.dart';

import 'utility.dart';

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
        title: const Text("Route Instructions", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple[900],
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: widget.instructionList.length,
        separatorBuilder: (context, index) => const Divider(
          indent: 50,
          height: 0,
        ),
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
        child: Image.memory(widget.instruction.turnDetails
            .getAbstractGeometryImage(renderSettings: AbstractGeometryImageRenderSettings(), size: Size(100, 100))),
      ),
      title: Text(
        widget.instruction.turnInstruction,
        overflow: TextOverflow.fade,
        style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w400),
        maxLines: 2,
      ),
      subtitle: Text(
        widget.instruction.followRoadInstruction,
        overflow: TextOverflow.fade,
        style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w400),
        maxLines: 2,
      ),
      trailing: Text(
        widget.instruction.getFormattedDistanceUntilInstruction(),
        overflow: TextOverflow.fade,
        style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w400),
      ),
    );
  }
}
