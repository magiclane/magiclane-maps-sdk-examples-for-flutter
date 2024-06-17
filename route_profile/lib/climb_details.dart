import 'package:flutter/material.dart' hide Route;
import 'package:gem_kit/core.dart';

import 'utility.dart';

class ClimbDetails extends StatelessWidget {
  final Route route;
  const ClimbDetails({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Climb Details'),
          Table(
            border: TableBorder(
                verticalInside: BorderSide(
                    width: 0.5,
                    color: Theme.of(context).colorScheme.outlineVariant,
                    style: BorderStyle.solid),
                horizontalInside: BorderSide(
                    width: 0.5,
                    color: Theme.of(context).colorScheme.outlineVariant,
                    style: BorderStyle.solid)),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            children: [
              const TableRow(children: [
                Text('Rating'),
                Text(
                  "Start/End Points\nStart/End Elevation",
                  maxLines: 2,
                ),
                Text(
                  "Length",
                  maxLines: 1,
                ),
                Text(
                  "Avg Grade",
                  maxLines: 2,
                ),
              ]),
              for (final section in route.terrainProfile!.climbSections)
                TableRow(
                    decoration: BoxDecoration(color: getGradeColor(section)),
                    children: [
                      Text(_getGradeString(section.grade!)),
                      Text(
                        '${convertDistance(section.startDistanceM!.toDouble())} / ${convertDistance(section.endDistanceM!.toDouble())}\n${convertDistance(_getSectionStartElevation(section))} / ${convertDistance(_getSectionEndElevation(section))}',
                        maxLines: 2,
                      ),
                      Text(
                        convertDistance(
                            (section.endDistanceM! - section.startDistanceM!)
                                .toDouble()),
                        maxLines: 2,
                      ),
                      Text(
                        "${section.slope!.toStringAsFixed(2)}%",
                        maxLines: 2,
                      )
                    ]),
            ],
          ),
        ],
      ),
    );
  }

  double _getSectionStartElevation(ClimbSection section) {
    return route.terrainProfile!.getElevation(section.startDistanceM ?? 0);
  }

  double _getSectionEndElevation(ClimbSection section) {
    return route.terrainProfile!
        .getElevation(section.endDistanceM ?? route.totalDistance());
  }

  String _getGradeString(Grade grade) {
    switch (grade) {
      case Grade.grade1:
        return "1";
      case Grade.grade2:
        return "2";
      case Grade.grade3:
        return "3";
      case Grade.grade4:
        return "4";
      case Grade.gradeHC:
        return "HC";
    }
  }
}
