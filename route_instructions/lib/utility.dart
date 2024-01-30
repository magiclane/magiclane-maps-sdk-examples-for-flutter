import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

String convertDistance(int meters) {
  if (meters >= 1000) {
    double kilometers = meters / 1000;
    return '${kilometers.toStringAsFixed(1)} km';
  } else {
    return '${meters.toString()} m';
  }
}

String convertDuration(int seconds) {
  int hours = seconds ~/ 3600; // Number of whole hours
  int minutes = (seconds % 3600) ~/ 60; // Number of whole minutes

  String hoursText = (hours > 0) ? '$hours h ' : ''; // Hours text
  String minutesText = '$minutes min'; // Minutes text

  return hoursText + minutesText;
}

Future<Uint8List?> decodeImageData(
    {required Uint8List data, int width = 100, int height = 100}) async {
  Completer<Uint8List?> c = Completer<Uint8List?>();

  decodeImageFromPixels(data, width, height, PixelFormat.rgba8888,
      (Image img) async {
    final data = await img.toByteData(format: ImageByteFormat.png);
    if (data == null) {
      c.complete(null);
    }
    final list = data!.buffer.asUint8List();
    c.complete(list);
  });

  return c.future;
}
