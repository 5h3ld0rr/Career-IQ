import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  static final String _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static final String _uploadPreset =
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  Future<String?> uploadFile({
    required dynamic file,
    required String folder,
    String? fileName,
    bool isImage = true,
  }) async {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      throw Exception('Cloudinary configuration missing in .env');
    }

    try {
      final resourceType = isImage ? 'image' : 'raw';
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
      );

      final request = http.MultipartRequest('POST', url);

      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder;

      if (file is String) {
        request.files.add(await http.MultipartFile.fromPath('file', file));
      } else {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file,
            filename:
                fileName ?? 'upload_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url'];
      } else {
        throw Exception(
          'Cloudinary upload failed: ${jsonResponse['error']['message']}',
        );
      }
    } catch (e) {
      debugPrint('Cloudinary Error: $e');
      rethrow;
    }
  }
}
