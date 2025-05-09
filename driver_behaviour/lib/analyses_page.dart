// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:flutter/material.dart';
import 'package:gem_kit/driver_behaviour.dart';
import 'package:intl/intl.dart';
import 'package:driver_behaviour/utils.dart';

class AnalysesPage extends StatelessWidget {
  final List<DriverBehaviourAnalysis> behaviourAnalyses;
  const AnalysesPage({super.key, required this.behaviourAnalyses});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyses', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple[900],
        foregroundColor: Colors.white,
      ),
      body:
          behaviourAnalyses.isEmpty
              ? const Center(child: Text('No analyses recorded'))
              : ListView.builder(
                itemCount: behaviourAnalyses.length,
                itemBuilder: (_, i) {
                  final a = behaviourAnalyses[i];
                  if (!a.isValid) {
                    return const ListTile(title: Text('Invalid analysis'));
                  }
                  final start =
                      DateTime.fromMillisecondsSinceEpoch(
                        a.startTime,
                      ).toLocal();
                  final end =
                      DateTime.fromMillisecondsSinceEpoch(
                        a.finishTime,
                      ).toLocal();
                  final dur = end.difference(start);

                  // Build a list of simple Text rows
                  final rows = <Widget>[
                    _buildRow('Start', fmt.format(start)),
                    _buildRow('End', fmt.format(end)),
                    _buildRow('Duration', formatDuration(dur)),
                    _buildRow(
                      'Distance (km)',
                      a.kilometersDriven.toStringAsFixed(2),
                    ),
                    _buildRow(
                      'Driving Time (min)',
                      a.minutesDriven.toStringAsFixed(1),
                    ),
                    _buildRow(
                      'Total Elapsed (min)',
                      a.minutesTotalElapsed.toStringAsFixed(1),
                    ),
                    _buildRow(
                      'Speeding (min)',
                      a.minutesSpeeding.toStringAsFixed(1),
                    ),
                    _buildRow(
                      'Risk Mean Speed (%)',
                      formatPercent(a.riskRelatedToMeanSpeed),
                    ),
                    _buildRow(
                      'Risk Speed Var (%)',
                      formatPercent(a.riskRelatedToSpeedVariation),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Events:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildRow(
                      'Harsh Accel',
                      a.numberOfHarshAccelerationEvents.toString(),
                    ),
                    _buildRow(
                      'Harsh Braking',
                      a.numberOfHarshBrakingEvents.toString(),
                    ),
                    _buildRow(
                      'Cornering',
                      a.numberOfCorneringEvents.toString(),
                    ),
                    _buildRow('Swerving', a.numberOfSwervingEvents.toString()),
                    _buildRow(
                      'Ignored Stops',
                      a.numberOfIgnoredStopSigns.toString(),
                    ),
                    _buildRow(
                      'Stop Signs',
                      a.numberOfEncounteredStopSigns.toString(),
                    ),
                  ];

                  return ExpansionTile(
                    title: Text('Trip ${i + 1}'),
                    subtitle: Text(fmt.format(start)),
                    childrenPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: rows,
                  );
                },
              ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }
}
