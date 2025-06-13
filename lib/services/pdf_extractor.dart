// lib/services/pdf_extractor.dart

import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:pdfx/pdfx.dart';
import '../utils/image_utils.dart';

class PdfExtractor {
  /// Extrae texto por página. Si estás en Web usa [fileBytes],
  /// si no en Web prefiere [filePath].
  static Future<List<String>> extractTextByPage({
    Uint8List? fileBytes,
    String? filePath,
  }) async {
    // 1) Obtén los bytes del PDF
    final Uint8List data = kIsWeb
        ? (fileBytes ?? Uint8List(0))
        : (filePath != null
        ? await File(filePath).readAsBytes()
        : (fileBytes ?? Uint8List(0)));

    // 2) Usa Syncfusion para extraer texto en todas las plataformas
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: data);
    final sf.PdfTextExtractor extractor = sf.PdfTextExtractor(document);

    final int pageCount = document.pages.count;
    final List<String> pages = [];
    for (var i = 0; i < pageCount; i++) {
      pages.add(
        extractor.extractText(startPageIndex: i, endPageIndex: i),
      );
    }

    document.dispose();
    return pages;
  }

  /// Renderiza la página [pageIndex] a PNG bytes.
  /// En Web usa openData, en otros openFile.
  /// Renderiza la página [pageIndex] a PNG y devuelve los bytes.
  static Future<Uint8List> pageToImage({
    Uint8List? fileBytes,
    String? filePath,
    required int pageIndex,
  }) async {
    // 1) Abrir documento: si es Web, PASAMOS UNA COPIA de los bytes
    final PdfDocument doc = kIsWeb
        ? await PdfDocument.openData(Uint8List.fromList(fileBytes!))
        : await PdfDocument.openFile(filePath!);

    // 2) Obtener la página (indexado desde 1)
    final PdfPage page = await doc.getPage(pageIndex + 1);

    // 3) Renderizar
    final PdfPageImage? pageImage = await page.render(
      width: page.width,
      height: page.height,
      format: PdfPageImageFormat.png,
    );

    if (pageImage == null) {
      await page.close();
      await doc.close();
      throw Exception('No se pudo renderizar la página $pageIndex');
    }

    final Uint8List pngBytes = pageImage.bytes;

    // 4) Liberar recursos
    await page.close();
    await doc.close();

    return pngBytes;
  }
}
