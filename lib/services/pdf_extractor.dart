// lib/services/pdf_extractor.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:pdfx/pdfx.dart';

import '../utils/image_utils.dart';

class PdfExtractor {
  /// Extrae el texto de cada página usando Syncfusion Flutter PDF.
  static Future<List<String>> extractTextByPage(File file) async {
    final bytes = await file.readAsBytes();
    final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
    final sf.PdfTextExtractor extractor = sf.PdfTextExtractor(document);

    final int pageCount = document.pages.count;
    final List<String> pages = <String>[];
    for (int i = 0; i < pageCount; i++) {
      pages.add(
        extractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        ),
      );
    }

    document.dispose();
    return pages;
  }

  /// Renderiza la página [pageIndex] a PNG y devuelve los bytes.
  /// Maneja el caso en que `render` devuelva null.
  static Future<Uint8List> pageToImage(File file, int pageIndex) async {
    // 1. Abrir documento con PDFx
    final PdfDocument doc = await PdfDocument.openFile(file.path);
    // 2. Obtener la página (indexado desde 1)
    final PdfPage page = await doc.getPage(pageIndex + 1);

    // 3. Renderizar la página. `render` puede devolver null, lo controlamos.
    final PdfPageImage? pageImage = await page.render(
      width: page.width,      // ahora usamos double
      height: page.height,    // sin conversión a int
      format: PdfPageImageFormat.png,
    );

    if (pageImage == null) {
      await page.close();
      await doc.close();
      throw Exception('Error: no se pudo renderizar la página $pageIndex');
    }

    // 4. Extraer los bytes PNG directo de pageImage
    final Uint8List pngBytes = pageImage.bytes;

    // 5. Liberar recursos
    await page.close();
    await doc.close();

    return pngBytes;
  }
}
