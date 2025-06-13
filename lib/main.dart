// lib/main.dart
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'services/pdf_extractor.dart';
import 'services/qr_decoder.dart';
import 'services/signer.dart';
import 'utils/image_utils.dart';
import 'models/validation_result.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Validator',
      home: const HomePage(),
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
    );
    if (result == null) return;
    final file = File(result.files.single.path!);

    // 1) Texto por página
    final pages = await PdfExtractor.extractTextByPage(file);
    // 2) Imágenes + QR
    final qrCodes = <String>[];
    for (var i = 0; i < pages.length; i++) {
      final img = await PdfExtractor.pageToImage(file, i);
      final data = await QrDecoder.decodeFromBytes(img);
      if (data != null) qrCodes.add(data);
    }
    // 3) Firma (stub)
    final fullText = pages.join('\n');
    final seal = Signer.extractSeal(fullText);
    final valid = await Signer.verify(fullText, seal);

    final resultJson = ValidationResult(
      filename: file.path.split('/').last,
      numPages: pages.length,
      qrCodes: qrCodes,
      signatureValid: valid,
      seal: seal,
    ).toJson();

    setState(() {
      _output = const JsonEncoder.withIndent('  ').convert(resultJson);
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
