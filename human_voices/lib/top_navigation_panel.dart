import 'package:human_voices/instruction_model.dart';
import 'package:flutter/material.dart';

class NavigationInstructionPanel extends StatelessWidget {
  final InstructionModel instruction;

  const NavigationInstructionPanel({super.key, required this.instruction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 20,
      height: MediaQuery.of(context).size.height * 0.25,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15)),
      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(20),
          width: 100,
          child: instruction.nextTurnImageData != null ? RawImage(image: instruction.nextTurnImageData!) : Container(),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width - 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                instruction.nextTurnDistance,
                textAlign: TextAlign.left,
                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w600),
              ),
              Text(
                instruction.nextStreetName,
                style: const TextStyle(
                    color: Colors.white, fontSize: 25, fontWeight: FontWeight.w600, overflow: TextOverflow.ellipsis),
              )
            ],
          ),
        ),
      ]),
    );
  }
}
