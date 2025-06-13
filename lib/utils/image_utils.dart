// lib/utils/image_utils.dart
import 'dart:typed_data';

import 'package:pdf_render/pdf_render.dart';
import 'package:image/image.dart' as img;

class ImageUtils {
  /// Toma un PdfPageImage (raw RGBA) y codifica un PNG.
  static Future<Uint8List> pageImageToPngBytes(PdfPageImage pageImage) async {
    // pdf_render te da pixels como Uint8List, pero image.fromBytes necesita ByteBuffer:
    final ByteBuffer buffer = pageImage.pixels.buffer;

    final image = img.Image.fromBytes(
      width: pageImage.width,
      height: pageImage.height,
      bytes: buffer,
      numChannels: 4,   // RGBA → 4 canales
    );

    final List<int> pngBytes = img.encodePng(image);
    return Uint8List.fromList(pngBytes);
  }
}
