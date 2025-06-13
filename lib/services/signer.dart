// lib/services/signer.dart
import 'dart:convert';

class Signer {
  /// Extrae del texto completo la porción que creas que contiene el sello.
  /// Este stub busca la línea que empieza con "Sello" y toma lo que sigue.
  static String extractSeal(String fullText) {
    final lines = fullText.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().contains('sello')) {
        return line.split(':').last.trim();
      }
    }
    return '';
  }

  /// Stub de verificación: aquí deberás cargar tu clave pública y usar pointycastle.
  static Future<bool> verify(String message, String base64Seal) async {
    if (message.isEmpty || base64Seal.isEmpty) return false;

    // TODO: implementa RSA-SHA256 con pointycastle usando tu certificado en assets.
    // Por ahora devolvemos true si hay algo de seal.
    return base64Seal.isNotEmpty;
  }
}
