import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

Future<Uint8List?> decodeImageData(Uint8List data,
    {int width = 100, int height = 100}) async {
  final completer = Completer<Uint8List?>();

  ui.decodeImageFromPixels(data, width, height, ui.PixelFormat.rgba8888,
      (ui.Image img) async {
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    completer.complete(data?.buffer.asUint8List());
  });

  return completer.future;
}
