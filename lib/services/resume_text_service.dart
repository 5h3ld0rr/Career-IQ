import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ResumeTextService {
  static Future<String> extractTextFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return await extractTextFromBytes(response.bodyBytes);
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  static Future<String> extractTextFromBytes(Uint8List bytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      return '';
    }
  }
}
