// SPDX-FileCopyrightText: 2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:flutter/material.dart';
import 'package:follow_position_advanced/follow_position_controller.dart';
import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';

class FollowPositionControlsPanel extends StatelessWidget {
  const FollowPositionControlsPanel({super.key, required this.controller});

  final FollowPositionController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton(
                  icon: Icons.start,
                  label: 'Start',
                  onPressed: controller.startFollowingPosition,
                ),
                _actionButton(
                  icon: Icons.stop,
                  label: 'Stop',
                  onPressed: controller.stopFollowingPosition,
                ),
                _actionButton(
                  icon: Icons.camera,
                  label: 'Restore',
                  onPressed: controller.restoreFollowingPosition,
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _sectionHeader('Start Follow Position Options'),
                  _sectionDescription(
                    'Start following keeps the map camera centered on the tracker and lets you predefine the zoom and tilt before the animation begins.',
                  ),
                  SwitchListTile(
                    title: const Text('Use default follow position options'),
                    value: controller.useDefaultStartFollowPosition,
                    onChanged: (value) => controller.updateValues(() {
                      controller.useDefaultStartFollowPosition = value;
                    }),
                  ),
                  if (!controller.useDefaultStartFollowPosition)
                    _sliderTile(
                      label: 'Zoom level',
                      value: controller.startZoomLevel.toDouble(),
                      min: 0,
                      max: 100,
                      onChanged: (value) => controller.updateValues(() {
                        controller.startZoomLevel = value.round();
                      }),
                      valueLabel: controller.startZoomLevel.toString(),
                    ),

                  if (!controller.useDefaultStartFollowPosition)
                    _sliderTile(
                      label: 'View angle',
                      value: controller.startViewAngle,
                      min: 0,
                      max: 90,
                      onChanged: (value) => controller.updateValues(() {
                        controller.startViewAngle = value;
                      }),
                      valueLabel:
                          '${controller.startViewAngle.toStringAsFixed(0)}°',
                    ),
                  _actionButton(
                    label: 'Start Following Position',
                    icon: Icons.my_location,
                    onPressed: controller.startFollowingPosition,
                  ),
                  const SizedBox(height: 12),
                  _sectionHeader('Camera focus'),
                  _sectionDescription(
                    'Move the tracker inside the viewport so the camera keeps more of the route ahead in view.',
                  ),
                  _sliderTile(
                    label: 'Focus X',
                    value: controller.cameraFocusX,
                    min: 0,
                    max: 1,
                    onChanged: (value) => controller.updateValues(() {
                      controller.cameraFocusX = value;
                    }),
                    valueLabel: controller.cameraFocusX.toStringAsFixed(2),
                  ),
                  _sliderTile(
                    label: 'Focus Y',
                    value: controller.cameraFocusY,
                    min: 0,
                    max: 1,
                    onChanged: (value) => controller.updateValues(() {
                      controller.cameraFocusY = value;
                    }),
                    valueLabel: controller.cameraFocusY.toStringAsFixed(2),
                  ),
                  _applyButton('Apply focus', controller.applyCameraFocus),
                  const SizedBox(height: 12),
                  _sectionHeader('Perspective'),
                  _sectionDescription(
                    'Swap between 2D bird-eye or 3D perspective views to change.',
                  ),
                  DropdownButton<MapViewPerspective>(
                    value: controller.perspective,
                    isExpanded: true,
                    items: MapViewPerspective.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => controller.updateValues(() {
                      if (value != null) {
                        controller.perspective = value;
                      }
                    }),
                  ),
                  SwitchListTile(
                    title: const Text('Animate perspective'),
                    value: controller.animatePerspective,
                    onChanged: (value) => controller.updateValues(() {
                      controller.animatePerspective = value;
                    }),
                  ),
                  _applyButton(
                    'Apply perspective',
                    controller.applyPerspective,
                  ),
                  const SizedBox(height: 12),
                  _sectionHeader('View angle'),
                  _sectionDescription(
                    'Tilt the camera from top-down to angled to show more horizon when following a route.',
                  ),
                  _sliderTile(
                    label: 'View angle',
                    value: controller.viewAngle,
                    min: 0,
                    max: 90,
                    onChanged: (value) => controller.updateValues(() {
                      controller.viewAngle = value;
                    }),
                    valueLabel: '${controller.viewAngle.toStringAsFixed(0)}°',
                  ),
                  SwitchListTile(
                    title: const Text('Animate view angle'),
                    value: controller.animateViewAngle,
                    onChanged: (value) => controller.updateValues(() {
                      controller.animateViewAngle = value;
                    }),
                  ),
                  _applyButton('Apply view angle', controller.applyViewAngle),
                  const SizedBox(height: 12),
                  _sectionHeader('Zoom'),
                  _sectionDescription('Control the follow camera zoom level.'),
                  SwitchListTile(
                    title: const Text('Auto zoom'),
                    value: controller.autoZoom,
                    onChanged: (value) => controller.updateValues(() {
                      controller.autoZoom = value;
                    }),
                  ),
                  if (!controller.autoZoom)
                    _sliderTile(
                      label: 'Zoom level',
                      value: controller.zoomLevel.toDouble(),
                      min: 0,
                      max: 100,
                      onChanged: (value) => controller.updateValues(() {
                        controller.zoomLevel = value.round();
                      }),
                      valueLabel: controller.zoomLevel.toString(),
                    ),
                  _sliderTile(
                    label: 'Zoom animation (ms)',
                    value: controller.zoomDuration.toDouble(),
                    min: 0,
                    max: 2000,
                    onChanged: (value) => controller.updateValues(() {
                      controller.zoomDuration = value.round();
                    }),
                    valueLabel: controller.zoomDuration.toString(),
                  ),
                  _applyButton('Apply zoom', controller.applyZoomLevel),
                  const SizedBox(height: 12),
                  _sectionHeader('Map rotation'),
                  _sectionDescription(
                    'Choose whether the map rotates with your heading, the compass, or stays fixed at a custom angle.',
                  ),
                  DropdownButton<FollowPositionMapRotationMode>(
                    value: controller.mapRotationMode,
                    isExpanded: true,
                    items: FollowPositionMapRotationMode.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => controller.updateValues(() {
                      if (value != null) {
                        controller.mapRotationMode = value;
                      }
                    }),
                  ),
                  if (controller.mapRotationMode ==
                      FollowPositionMapRotationMode.fixed)
                    _sliderTile(
                      label: 'Fixed map angle',
                      value: controller.mapAngle,
                      min: 0,
                      max: 360,
                      onChanged: (value) => controller.updateValues(() {
                        controller.mapAngle = value;
                      }),
                      valueLabel: '${controller.mapAngle.toStringAsFixed(0)}°',
                    ),
                  SwitchListTile(
                    title: const Text('Tracker follows map rotation'),
                    value: controller.objectFollowMap,
                    onChanged: (value) => controller.updateValues(() {
                      controller.objectFollowMap = value;
                    }),
                  ),
                  _applyButton(
                    'Apply rotation',
                    controller.applyMapRotationMode,
                  ),
                  const SizedBox(height: 12),
                  _sectionHeader('Touch handler'),
                  _sectionDescription(
                    'Decide if touch gestures kick you out of follow mode and how much pan/tilt/distance adjustments persist.',
                  ),
                  SwitchListTile(
                    title: const Text('Allow exit by touch'),
                    value: controller.touchHandlerExitAllow,
                    onChanged: (value) => controller.updateValues(() {
                      controller.touchHandlerExitAllow = value;
                    }),
                  ),
                  _applyButton(
                    'Apply touch exit',
                    controller.applyTouchHandlerExitAllow,
                  ),
                  SwitchListTile(
                    title: const Text('Persist touch adjustments'),
                    value: controller.touchHandlerModifyPersistent,
                    onChanged: (value) => controller.updateValues(() {
                      controller.touchHandlerModifyPersistent = value;
                    }),
                  ),
                  _applyButton(
                    'Apply persistence',
                    controller.applyTouchHandlerModifyPersistent,
                  ),
                  _rangeSliderTile(
                    label: 'Horizontal angle limits',
                    values: controller.horizontalAngleLimits,
                    min: 0,
                    max: 180,
                    onChanged: (values) => controller.updateValues(() {
                      controller.horizontalAngleLimits = values;
                    }),
                  ),
                  _applyButton(
                    'Apply horizontal limits',
                    controller.applyHorizontalAngleLimits,
                  ),
                  _rangeSliderTile(
                    label: 'Vertical angle limits',
                    values: controller.verticalAngleLimits,
                    min: 0,
                    max: 90,
                    onChanged: (values) => controller.updateValues(() {
                      controller.verticalAngleLimits = values;
                    }),
                  ),
                  _applyButton(
                    'Apply vertical limits',
                    controller.applyVerticalAngleLimits,
                  ),
                  SwitchListTile(
                    title: const Text('Unlimited distance max'),
                    value: controller.distanceMaxUnlimited,
                    onChanged: (value) => controller.updateValues(() {
                      controller.distanceMaxUnlimited = value;
                    }),
                  ),
                  _rangeSliderTile(
                    label: 'Distance limits (m)',
                    values: controller.distanceLimits,
                    min: 0,
                    max: 1000,
                    onChanged: (values) => controller.updateValues(() {
                      controller.distanceLimits = values;
                    }),
                  ),
                  _applyButton(
                    'Apply distance limits',
                    controller.applyDistanceLimits,
                  ),
                  const SizedBox(height: 12),
                  _sectionHeader('Turn presentation'),
                  _sectionDescription(
                    'Sets how many seconds before an upcoming turn the map camera should start presenting the turn animation.',
                  ),
                  SwitchListTile(
                    title: const Text('Use SDK default'),
                    value: controller.useDefaultTurnPresentationTime,
                    onChanged: (value) => controller.updateValues(() {
                      controller.useDefaultTurnPresentationTime = value;
                    }),
                  ),
                  if (!controller.useDefaultTurnPresentationTime)
                    _sliderTile(
                      label: 'Seconds before turn',
                      value: controller.turnPresentationSeconds,
                      min: 0,
                      max: 30,
                      onChanged: (value) => controller.updateValues(() {
                        controller.turnPresentationSeconds = value;
                      }),
                      valueLabel:
                          '${controller.turnPresentationSeconds.toStringAsFixed(0)} s',
                    ),
                  _applyButton(
                    'Apply turn time',
                    controller.applyTurnPresentationTime,
                  ),
                  const SizedBox(height: 12),
                  _sectionHeader('Position tracker'),
                  _sectionDescription(
                    'Scale the tracker icon, independent of map zoom level.',
                  ),
                  _sliderTile(
                    label: 'Tracker scale',
                    value: controller.positionTrackerScale,
                    min: 0.2,
                    max: 2,
                    onChanged: (value) => controller.updateValues(() {
                      controller.positionTrackerScale = value;
                    }),
                    valueLabel: controller.positionTrackerScale.toStringAsFixed(
                      2,
                    ),
                  ),
                  _applyButton(
                    'Apply tracker scale',
                    controller.applyPositionTrackerScale,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _sectionDescription(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Colors.black54),
      ),
    );
  }

  Widget _sliderTile({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double>? onChanged,
    required String valueLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: $valueLabel'),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _rangeSliderTile({
    required String label,
    required RangeValues values,
    required double min,
    required double max,
    required ValueChanged<RangeValues>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ${values.start.toStringAsFixed(1)} → ${values.end.toStringAsFixed(1)}',
          ),
          RangeSlider(
            values: RangeValues(
              values.start.clamp(min, max),
              values.end.clamp(min, max),
            ),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _applyButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ElevatedButton(onPressed: onPressed, child: Text(label)),
      ),
    );
  }

  Widget _actionButton({
    String? label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    if (label == null) {
      return ElevatedButton(onPressed: onPressed, child: Icon(icon));
    } else {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }
  }
}
