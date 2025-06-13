// lib/services/pdf_validator.dart

import 'dart:io';
import 'dart:typed_data';

import '../services/pdf_extractor.dart';
import '../services/qr_decoder.dart';
import '../services/signer.dart';
import '../models/validation_result.dart';

class PdfValidator {
  /// Valida localmente un PDF (texto, QR y firma) y devuelve el resultado.
  static Future<ValidationResult> validatePdf({
    Uint8List? fileBytes,
    String? filePath,
  }) async {
    // 1) Texto por página
    final pages = await PdfExtractor.extractTextByPage(
      fileBytes: fileBytes,
      filePath: filePath,
    );
    final int numPages = pages.length;

    // 2) QR por página
    final List<String> qrCodes = [];
    for (var i = 0; i < numPages; i++) {
      final imageBytes = await PdfExtractor.pageToImage(
        fileBytes: fileBytes,
        filePath: filePath,
        pageIndex: i,
      );
      final qr = await QrDecoder.decodeFromBytes(imageBytes);
      if (qr != null && qr.isNotEmpty) qrCodes.add(qr);
    }

    // 3) Firma
    final fullText = pages.join('\n');
    final seal = Signer.extractSeal(fullText);
    final bool signatureValid = await Signer.verify(fullText, seal);

    // 4) Construir resultado
    return ValidationResult(
      filename: filePath != null
          ? filePath.split(Platform.pathSeparator).last
          : 'document.pdf',
      numPages: numPages,
      qrCodes: qrCodes,
      signatureValid: signatureValid,
      seal: seal,
    );
  }
}
