// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:flutter/material.dart';
import 'package:gem_kit/sense.dart' as sense;
import 'package:gem_kit/position.dart' as position;

/// Device sensors UI
class DeviceSensorsDataPage extends StatefulWidget {
  const DeviceSensorsDataPage({super.key});

  @override
  State<DeviceSensorsDataPage> createState() => _DeviceSensorsDataPageState();
}

class _DeviceSensorsDataPageState extends State<DeviceSensorsDataPage> {
  sense.DataType? _selectedType;
  final Map<sense.DataType, sense.SenseData> _latest = {};
  sense.DataSource? _dataSource;
  sense.DataSourceListener? _listener;

  @override
  void initState() {
    super.initState();
    _initDataSourceAndListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.deepPurple[900],
        title: const Text(
          'Device Sensors Data',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildButtonsRow(),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SingleChildScrollView(
                child: Text(
                  _displayFor(_selectedType),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initDataSourceAndListeners() async {
    _dataSource = sense.DataSource.createLiveDataSource();
    if (_dataSource == null) {
      // Live data not available.
      return;
    }

    _listener = sense.DataSourceListener(
      onNewData: (sense.SenseData data) {
        if (!mounted) return;
        setState(() {
          _latest[data.type] = data;
        });
      },
    );

    for (final t in sense.DataType.values) {
      if (t == sense.DataType.unknown) continue;
      _dataSource!.addListener(listener: _listener!, dataType: t);
    }

    _dataSource!.start();
  }

  @override
  void dispose() {
    try {
      if (_listener != null) {
        for (final t in sense.DataType.values) {
          if (t == sense.DataType.unknown) continue;
          _dataSource?.removeListener(listener: _listener!, dataType: t);
        }
      }
      _listener?.dispose();
      _dataSource?.dispose();
    } catch (_) {
      // ignore errors during cleanup
    }
    super.dispose();
  }

  Widget _buildButtonsRow() {
    final types = sense.DataType.values
        .where(
          (t) => t != sense.DataType.unknown && t != sense.DataType.gyroscope,
        )
        .toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: types.map((t) {
          final selected = t == _selectedType;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ChoiceChip(
              label: Text(t.toString().split('.').last),
              selected: selected,
              onSelected: (_) => setState(() => _selectedType = t),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _displayFor(sense.DataType? type) {
    if (type == null) return 'No type selected.';
    final data = _latest[type];
    if (data == null)
      return 'No data received yet for ${type.toString().split('.').last}.';

    switch (type) {
      case sense.DataType.acceleration:
        final d = data as sense.Acceleration;
        return 'Acceleration x=${d.x} y=${d.y} z=${d.z} ${d.unit}';
      case sense.DataType.attitude:
        final d = data as sense.Attitude;
        return 'Attitude roll=${d.roll} pitch=${d.pitch} yaw=${d.yaw}';
      case sense.DataType.battery:
        final d = data as sense.Battery;
        return 'Battery level=${d.level}% state=${d.state}';
      case sense.DataType.camera:
        final d = data as sense.Camera;
        final cfg = d.cameraConfiguration;
        return 'Camera ${cfg.frameWidth}x${cfg.frameHeight}@${cfg.frameRate}fps';
      case sense.DataType.compass:
        final d = data as sense.Compass;
        return 'Heading=${d.heading}° acc=${d.accuracy}';
      case sense.DataType.magneticField:
        final d = data as sense.MagneticField;
        return 'Mag x=${d.x} y=${d.y} z=${d.z} µT';
      case sense.DataType.orientation:
        final d = data as sense.Orientation;
        return 'Orientation=${d.orientation} face=${d.face}';
      case sense.DataType.position:
        final d = data as position.GemPosition;
        return 'Pos ${d.latitude.toStringAsFixed(6)}, ${d.longitude.toStringAsFixed(6)} alt=${d.altitude}m';
      case sense.DataType.improvedPosition:
        final d = data as position.GemImprovedPosition;
        final roadMods = d.roadModifiers.isEmpty
            ? 'none'
            : d.roadModifiers
                  .map((m) => m.toString().split('.').last)
                  .join(',');
        final addr = () {
          try {
            return d.address.format();
          } catch (_) {
            return '';
          }
        }();

        final sb = StringBuffer();
        sb.writeln(
          'Position: ${d.latitude.toStringAsFixed(6)}, ${d.longitude.toStringAsFixed(6)}',
        );
        sb.writeln('Altitude: ${d.altitude} m');
        sb.writeln('Provider: ${d.provider.toString().split('.').last}');

        final speedLine = StringBuffer(
          'Speed: ${d.speed.toStringAsFixed(2)} m/s',
        );
        if (d.hasSpeedAccuracy)
          speedLine.write(' ±${d.speedAccuracy.toStringAsFixed(2)} m/s');
        sb.writeln(speedLine.toString());

        final courseLine = StringBuffer(
          'Course: ${d.course.toStringAsFixed(1)}°',
        );
        if (d.hasCourseAccuracy)
          courseLine.write(' ±${d.courseAccuracy.toStringAsFixed(1)}°');
        sb.writeln(courseLine.toString());
        sb.writeln('Fix quality: ${d.fixQuality.toString().split('.').last}');

        sb.writeln('Horizontal accuracy: ${d.accuracyH.toStringAsFixed(1)} m');
        sb.writeln('Vertical accuracy: ${d.accuracyV.toStringAsFixed(1)} m');

        // Improved-position specific fields
        sb.writeln('Road modifiers: $roadMods');
        sb.writeln('Speed limit: ${d.speedLimit.toStringAsFixed(2)} m/s');
        sb.writeln('Road localization: ${d.hasRoadLocalization}');
        sb.writeln('Terrain data available: ${d.hasTerrainData}');

        sb.writeln(
          'Terrain altitude: ${d.terrainAltitude.toStringAsFixed(1)} m',
        );
        sb.writeln('Terrain slope: ${d.terrainSlope.toStringAsFixed(1)}°');

        if (addr.isNotEmpty) sb.writeln('Address: $addr');

        return sb.toString().trim();
      case sense.DataType.rotationRate || sense.DataType.gyroscope:
        final d = data as sense.RotationRate;
        return 'RotationRate x=${d.x} y=${d.y} z=${d.z}';
      case sense.DataType.temperature:
        final d = data as sense.Temperature;
        return 'Temp=${d.temperature}°C level=${d.level}';
      case sense.DataType.notification:
        return 'Notification at ${data.acquisitionTime.toUtc()}';
      case sense.DataType.mountInformation:
        final d = data as sense.MountInformation;
        return 'Mounted=${d.isMountedForCameraUse} portrait=${d.isPortraitMode}';
      case sense.DataType.heartRate:
        final d = data as sense.HeartRate;
        return 'HR=${d.heartRate} bpm';
      case sense.DataType.nmeaChunk:
        final d = data as sense.NmeaChunk;
        return 'NMEA: ${d.nmeaChunk}';
      default:
        return 'Unknown';
    }
  }
}
