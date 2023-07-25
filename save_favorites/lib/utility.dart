import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

// Utility function to decode the raw image to a format supported by Flutter
Future<Uint8List?> decodeImageData(Uint8List data) async {
  Completer<Uint8List?> c = Completer<Uint8List?>();

  int width = 100;
  int height = 100;

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
