// lib/services/pdf_validator.dart

import 'dart:io';
import '../services/pdf_extractor.dart';
import '../services/qr_decoder.dart';
import '../services/signer.dart';
import '../models/validation_result.dart';

class PdfValidator {
  /// Recibe un [pdfFile], extrae texto, decodifica QRs y verifica la firma.
  /// Retorna un [ValidationResult] con el JSON listo para usar.
  static Future<ValidationResult> validatePdf(File pdfFile) async {
    // 1) Extraer texto de cada página
    final pages = await PdfExtractor.extractTextByPage(pdfFile);
    final int numPages = pages.length;

    // 2) Renderizar cada página, decodificar QR y acumular los datos
    final List<String> qrCodes = [];
    for (var i = 0; i < numPages; i++) {
      final imageBytes = await PdfExtractor.pageToImage(pdfFile, i);
      final qr = await QrDecoder.decodeFromBytes(imageBytes);
      if (qr != null && qr.isNotEmpty) {
        qrCodes.add(qr);
      }
    }

    // 3) Extraer el sello (firma) del texto completo
    final String fullText = pages.join('\n');
    final String seal = Signer.extractSeal(fullText);

    // 4) Verificar la firma contra la cadena original
    final bool signatureValid = await Signer.verify(fullText, seal);

    // 5) Construir y devolver el resultado
    return ValidationResult(
      filename: pdfFile.path.split(Platform.pathSeparator).last,
      numPages: numPages,
      qrCodes: qrCodes,
      signatureValid: signatureValid,
      seal: seal, // Si tu modelo lo admite; si no, puedes omitirlo
    );
  }
}
