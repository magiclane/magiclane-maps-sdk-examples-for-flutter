import 'package:flutter/material.dart';

import 'package:route_instructions/instruction_model.dart';

class RouteInstructionsPage extends StatefulWidget {
  final Future<List<RouteInstructionModel>> instructionList;

  const RouteInstructionsPage({super.key, required this.instructionList});

  @override
  State<RouteInstructionsPage> createState() => _RouteInstructionsState();
}

class _RouteInstructionsState extends State<RouteInstructionsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: const Text("Route Instructions",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurple[900],
          foregroundColor: Colors.white,
        ),
        body: FutureBuilder<List<RouteInstructionModel>>(
            future: widget.instructionList,
            builder: ((context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }
              return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: snapshot.data!.length,
                  controller: ScrollController(),
                  itemBuilder: (contex, index) {
                    final instruction = snapshot.data!.elementAt(index);
                    return InstructionsItem(instruction: instruction);
                  });
            })));
  }
}

class InstructionsItem extends StatefulWidget {
  final bool isLast;
  final RouteInstructionModel instruction;
  const InstructionsItem(
      {super.key, this.isLast = false, required this.instruction});

  @override
  State<InstructionsItem> createState() => _InstructionsItemState();
}

class _InstructionsItemState extends State<InstructionsItem> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: InkWell(
        onTap: () {},
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  width: 50,
                  child: Image.memory(widget.instruction.imageData!),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 140,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          widget.instruction.instruction,
                          overflow: TextOverflow.fade,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w400),
                          maxLines: 2,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 3),
                        child: Text(
                          widget.instruction.followingRoadinstruction,
                          overflow: TextOverflow.fade,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w400),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  widget.instruction.distanceUntilInstruction,
                  overflow: TextOverflow.fade,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w400),
                )
              ],
            ),
            const Divider(
              color: Colors.grey,
              indent: 10,
              endIndent: 20,
            )
          ],
        ),
      ),
    );
  }
}
