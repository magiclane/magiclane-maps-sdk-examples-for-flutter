// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

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
                profile.height.toDouble() < 1.8
                    ? 1.8
                    : profile.height.toDouble(),
                1.8,
                4.0, (value) {
              setState(() {
                profile.height = value.toInt();
              });
            }, "m"),
            _buildSlider(
                'Length',
                profile.length.toDouble() < 5.0
                    ? 5.0
                    : profile.length.toDouble(),
                5.0,
                20.0, (value) {
              setState(() {
                profile.length = value.toInt();
              });
            }, "m"),
            _buildSlider(
                'Width',
                profile.width.toDouble() < 2.0 ? 2.0 : profile.width.toDouble(),
                2.0,
                4.0, (value) {
              setState(() {
                profile.width = value.toInt();
              });
            }, "m"),
            _buildSlider(
                'Axle Weight',
                profile.axleLoad.toDouble() < 1.5
                    ? 1.5
                    : profile.axleLoad.toDouble(),
                1.5,
                10, (value) {
              setState(() {
                profile.axleLoad = value.toInt();
              });
            }, "t"),
            _buildSlider(
                'Max Speed',
                profile.maxSpeed < 60 ? 60 : profile.maxSpeed,
                60,
                250, (value) {
              setState(() {
                profile.maxSpeed = value;
              });
            }, "km/h"),
            _buildSlider(
                'Weight',
                profile.mass.toDouble() < 3.0 ? 3.0 : profile.mass.toDouble(),
                3.0,
                50.0, (value) {
              setState(() {
                profile.mass = value.toInt();
              });
            }, "t"),
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
  Widget _buildSlider(String label, double value, double min, double max,
      ValueChanged<double> onChanged, String measureUnit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                Text("$min $measureUnit"),
              ],
            ),
            Text("${value.toInt()} $measureUnit"),
            Text("$max $measureUnit"),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 100,
          label: value.toStringAsFixed(2),
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
