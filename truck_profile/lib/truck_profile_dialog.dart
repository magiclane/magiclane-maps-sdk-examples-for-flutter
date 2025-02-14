// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:flutter/material.dart';
import 'package:gem_kit/routing.dart';

// A widget that allows the user to view and modify various properties of the truck.
class TruckProfileDialog extends StatefulWidget {
  // The truck profile data to be modified in the dialog.
  final TruckProfile truckProfile;

  const TruckProfileDialog({super.key, required this.truckProfile});

  @override
  TruckProfileDialogState createState() => TruckProfileDialogState();
}

class TruckProfileDialogState extends State<TruckProfileDialog> {
  late TruckProfile profile;

  // Initializes the state of the dialog by copying the truck profile and setting initial values.
  @override
  void initState() {
    super.initState();
    profile = widget.truckProfile;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Truck Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sliders to adjust various truck parameters.
            _buildSlider(
              'Height',
              profile.height.toDouble() < 180 ? 180 : profile.height.toDouble(),
              180,
              400,
              (value) {
                setState(() {
                  profile.height = value.toInt();
                });
              },
              "cm",
            ),
            _buildSlider(
              'Length',
              profile.length.toDouble() < 500 ? 500 : profile.length.toDouble(),
              500,
              2000,
              (value) {
                setState(() {
                  profile.length = value.toInt();
                });
              },
              "cm",
            ),
            _buildSlider(
              'Width',
              profile.width.toDouble() < 200 ? 200 : profile.width.toDouble(),
              200,
              400,
              (value) {
                setState(() {
                  profile.width = value.toInt();
                });
              },
              "cm",
            ),
            _buildSlider(
              'Axle Load',
              profile.axleLoad.toDouble() < 1500
                  ? 1500
                  : profile.axleLoad.toDouble(),
              1500,
              10000,
              (value) {
                setState(() {
                  profile.axleLoad = value.toInt();
                });
              },
              "kg",
            ),
            _buildSlider(
              'Max Speed',
              profile.maxSpeed < 60 ? 60 : profile.maxSpeed,
              60,
              250,
              (value) {
                setState(() {
                  profile.maxSpeed = value;
                });
              },
              "km/h",
            ),

            _buildSlider(
              'Weight',
              profile.mass.toDouble() < 3000 ? 3000 : profile.mass.toDouble(),
              3000,
              50000,
              (value) {
                setState(() {
                  profile.mass = value.toInt();
                });
              },
              "kg",
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(profile);
          },
          child: Text('Done'),
        ),
      ],
    );
  }

  // Builds a slider widget for modifying a specific truck parameter.
  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    String measureUnit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(label), Text("$min $measureUnit")],
            ),
            Text("${value.toInt()}"),
            Text("$max $measureUnit"),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 100,
          label: value.toStringAsFixed(0),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// Shows the dialog and returns the updated truck profile.
void showTruckProfileDialog(BuildContext context, TruckProfile truckProfile) {
  showDialog<TruckProfile>(
    context: context,
    builder: (BuildContext context) {
      return TruckProfileDialog(truckProfile: truckProfile);
    },
  );
}
