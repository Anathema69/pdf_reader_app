// lib/models/validation_result.dart
class ValidationResult {
  final String filename;
  final int numPages;
  final List<String> qrCodes;
  final bool signatureValid;
  final String seal;

  ValidationResult({
    required this.filename,
    required this.numPages,
    required this.qrCodes,
    required this.signatureValid,
    required this.seal,
  });

  Map<String, dynamic> toJson() => {
    'filename': filename,
    'num_pages': numPages,
    'qr_codes': qrCodes,
    'seal': seal,
    'signature_valid': signatureValid,
  };
}
