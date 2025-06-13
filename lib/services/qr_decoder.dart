// lib/services/qr_decoder.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:qr_code_tools/qr_code_tools.dart';

class QrDecoder {
  /// Recibe los bytes de una imagen (PNG) y devuelve el contenido del QR si lo detecta, o null.
  /// Internamente escribe un archivo temporal y usa QrCodeToolsPlugin.decodeFrom().
  static Future<String?> decodeFromBytes(Uint8List imageBytes) async {
    try {
      // 1) Crear archivo temporal en la carpeta del sistema
      final tempDir = Directory.systemTemp;
      final tempFile = await File(
          '${tempDir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png'
      ).create();

      // 2) Escribir los bytes de la imagen
      await tempFile.writeAsBytes(imageBytes);

      // 3) Decodificar usando el plugin (solo acepta ruta de archivo) :contentReference[oaicite:0]{index=0}
      final data = await QrCodeToolsPlugin.decodeFrom(tempFile.path);

      // 4) Borrar el archivo temporal
      await tempFile.delete();

      return data;
    } catch (_) {
      return null;
    }
  }
}
