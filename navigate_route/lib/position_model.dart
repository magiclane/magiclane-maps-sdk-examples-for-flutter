import 'package:gem_kit/gem_kit_sense_basic.dart';

class PositionModel {
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? speed;
  PositionModel(
      {required this.latitude,
      required this.longitude,
      required this.altitude,
      required this.speed});

  static PositionModel fromGemPosition(gemPosition pos) {
    final latitude = pos.coordinates.latitude ?? 0;
    final longitude = pos.coordinates.longitude ?? 0;
    final altitude = pos.altitude;
    final speed = pos.speed > 0 ? pos.speed * 3.6 : 0.0;

    return PositionModel(
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        speed: speed);
  }
}
