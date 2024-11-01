import 'package:gem_kit/weather.dart';

extension ConditionExtension on Conditions {
  // Formatting the date for display.
  String getFormattedDate() {
    return "${stamp.day}/${stamp.month}/${stamp.year}";
  }

  // Formatting the temperature for display
  String getFormattedTemperature() {
    final tempHigh =
        params.where((element) => element.type == "TemperatureHigh").first;
    final tempLow =
        params.where((element) => element.type == "TemperatureLow").first;
    return '${tempHigh.value.toStringAsFixed(0)}${tempHigh.unit} / ${tempLow.value.toStringAsFixed(0)}${tempLow.unit}';
  }

  // Formatting the timestamp for display.
  String getFormattedHour() {
    return "${stamp.hour.toString().padLeft(2, '0')}:${stamp.minute.toString().padLeft(2, '0')}";
  }
}

extension ParameterExtension on Parameter {
  // Formatting parameter's seconds since the Unix epoch to DateTime for display
  String getFormattedHour() {
    return "${DateTime.fromMillisecondsSinceEpoch((value * 1000).toInt()).hour.toString().padLeft(2, '0')} : ${DateTime.fromMillisecondsSinceEpoch((value * 1000).toInt()).minute.toString().padLeft(2, '0')}";
  }
}

extension ForecastExtension on LocationForecast {
  // Formatting the timestamp for display.
  String getFormattedHour() {
    return "${(updated.hour).toString().padLeft(2, '0')} : ${updated.minute.toString().padLeft(2, '0')}";
  }
}
