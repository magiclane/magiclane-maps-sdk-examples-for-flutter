// SPDX-FileCopyrightText: 2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:flutter/material.dart';
import 'package:follow_position_advanced/follow_position_controller.dart';

class FollowPositionInfoPanel extends StatelessWidget {
  const FollowPositionInfoPanel({super.key, required this.controller});

  final FollowPositionController controller;

  @override
  Widget build(BuildContext context) {
    final info = controller.info;

    return Column(
      children: [
        ElevatedButton(
          onPressed: () => controller.refreshInfo(),
          child: const Text('Refresh Info'),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _infoTile(
                'Camera focus',
                '(${info.cameraFocus.x.toStringAsFixed(2)}, ${info.cameraFocus.y.toStringAsFixed(2)})',
              ),
              _infoTile('Perspective', info.perspective.name),
              _infoTile('View angle', '${info.viewAngle.toStringAsFixed(1)}°'),
              _infoTile('Zoom level', info.zoomLevel.toString()),
              _infoTile(
                'Time before turn',
                info.timeBeforeTurnPresentation.toString(),
              ),
              const Divider(),
              _infoTile('Map rotation mode', info.mapRotationMode.name),
              _infoTile(
                'Map rotation angle',
                '${info.mapRotationAngle.toStringAsFixed(1)}°',
              ),
              _infoTile(
                'Tracker follows map',
                info.isTrackObjectFollowingMapRotation.toString(),
              ),
              const Divider(),
              _infoTile(
                'Accuracy circle visible',
                info.accuracyCircleVisibility.toString(),
              ),
              _infoTile(
                'Accuracy circle color',
                info.accuracyCircleColor.toString(),
              ),
              _infoTile(
                'Tracker scale',
                info.positionTrackerScale.toStringAsFixed(2),
              ),
              const Divider(),
              _infoTile(
                'Touch exit allow',
                info.touchHandlerExitAllow.toString(),
              ),
              _infoTile(
                'Touch modify persistent',
                info.touchHandlerModifyPersistent.toString(),
              ),
              _infoTile(
                'Horizontal angle limits',
                _formatRange(info.touchHandlerModifyHorizontalAngleLimits),
              ),
              _infoTile(
                'Vertical angle limits',
                _formatRange(info.touchHandlerModifyVerticalAngleLimits),
              ),
              _infoTile(
                'Distance limits',
                _formatRange(info.touchHandlerModifyDistanceLimits, unit: 'm'),
              ),
              const Divider(),
              _infoTile(
                'Is following position',
                info.isFollowingPosition.toString(),
              ),
              _infoTile(
                'Is default follow',
                info.isDefaultFollowingPosition.toString(),
              ),
              _infoTile(
                'Touch modified follow',
                info.isFollowingPositionTouchHandlerModified.toString(),
              ),
              _infoTile('Is camera moving', info.isCameraMoving.toString()),
              const Divider(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value) {
    return ListTile(dense: true, title: Text(label), subtitle: Text(value));
  }

  String _formatRange((double, double) range, {String unit = '°'}) {
    final start = range.$1.toStringAsFixed(1);
    final end = range.$2.isInfinite ? '∞' : range.$2.toStringAsFixed(1);
    return '$start $unit → $end $unit';
  }
}
