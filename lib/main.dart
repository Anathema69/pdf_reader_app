// lib/main.dart

import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'services/pdf_extractor.dart';
import 'services/qr_decoder.dart';
import 'services/signer.dart';
import 'models/validation_result.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _output = '';

  Future<void> _pickAndValidate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,  // carga los bytes para Web
    );
    if (result == null) return;

    // 1) Saca nombre del archivo y bytes (siempre disponibles)
    final picked = result.files.single;
    final String fileName = picked.name;
    final Uint8List? fileBytes = picked.bytes;

    // 2) Sólo en nativo (Android/iOS/Desktop) usa .path
    final String? filePath = kIsWeb ? null : picked.path;

    // 3) Extrae texto por página
    final pages = await PdfExtractor.extractTextByPage(
      fileBytes: fileBytes,
      filePath:  filePath,
    );

    // 4) Decodifica QR en cada página
    final qrCodes = <String>[];
    for (var i = 0; i < pages.length; i++) {
      final imageBytes = await PdfExtractor.pageToImage(
        fileBytes: fileBytes,
        filePath:  filePath,
        pageIndex: i,
      );
      final qr = await QrDecoder.decodeFromBytes(imageBytes);
      if (qr != null && qr.isNotEmpty) qrCodes.add(qr);
    }

    // 5) Firma local (stub)
    final fullText = pages.join('\n');
    final seal     = Signer.extractSeal(fullText);
    final valid    = await Signer.verify(fullText, seal);

    // 6) Construye JSON de salida
    final json = ValidationResult(
      filename:        fileName,
      numPages:        pages.length,
      qrCodes:         qrCodes,
      signatureValid:  valid,
      seal:            seal,
    ).toJson();

    // 7) Actualiza la UI
    setState(() {
      _output = const JsonEncoder.withIndent('  ').convert(json);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Validator')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickAndValidate,
              child: const Text('Seleccionar y validar PDF'),
            ),
            const SizedBox(height: 20),
            Expanded(child: SingleChildScrollView(child: Text(_output))),
          ],
        ),
      ),
    );
  }
}
