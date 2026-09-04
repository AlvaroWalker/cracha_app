import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class RemoveBgService {
  static const String _apiKey = 'dXFbHV8yveffn4pYho6Yf5eE';
  static const String _apiUrl = 'https://api.remove.bg/v1.0/removebg';

  static Future<Uint8List> removeBackground(Uint8List imageBytes, {String filename = 'photo.jpg'}) async {
    final request = http.MultipartRequest('POST', Uri.parse(_apiUrl))
      ..headers['X-API-Key'] = _apiKey
      ..fields['size'] = 'auto'
      ..fields['bg_color'] = 'FFFFFF'   // <<< fundo branco
      ..files.add(http.MultipartFile.fromBytes(
        'image_file', imageBytes, filename: filename,
      ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) return response.bodyBytes;

    final errorBody = jsonDecode(response.body);
    final error = errorBody['errors']?[0]?['title'] ?? 'Erro desconhecido';
    throw Exception('Erro ao remover fundo: $error (${response.statusCode})');
  }
}
