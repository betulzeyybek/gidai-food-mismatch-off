
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/analysis_result.dart';

class ApiService {
  // Android emulator: http://10.0.2.2:8000
  // Real phone: use your Mac IP, e.g. http://192.168.1.34:8000
  // iOS simulator / desktop: http://127.0.0.1:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static Future<bool> health() async {
    final uri = Uri.parse('$baseUrl/health');
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getProductByBarcode(String barcode) async {
    final uri = Uri.parse('$baseUrl/product/barcode/$barcode');
    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Barkod servisi hata verdi: ${response.statusCode}');
    }

    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }



  static Future<AnalysisResult> analyzeBarcode(String barcode) async {
    final uri = Uri.parse('$baseUrl/analyze-barcode/$barcode');
    final response = await http.get(uri).timeout(const Duration(seconds: 35));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Barkod analiz servisi hata verdi: ${response.statusCode} - ${response.body}');
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return AnalysisResult.fromJson(json);
  }

  static Future<AnalysisResult> analyzeProduct({
    required String frontImagePath,
    required String ingredientsImagePath,
    String? barcode,
    String? productName,
    String? ingredientsTextFromBarcode,
  }) async {
    final uri = Uri.parse('$baseUrl/analyze-product');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath('front_image', frontImagePath),
    );
    request.files.add(
      await http.MultipartFile.fromPath('ingredients_image', ingredientsImagePath),
    );

    if (barcode != null && barcode.trim().isNotEmpty) {
      request.fields['barcode'] = barcode.trim();
    }
    if (productName != null && productName.trim().isNotEmpty) {
      request.fields['product_name'] = productName.trim();
    }
    if (ingredientsTextFromBarcode != null && ingredientsTextFromBarcode.trim().isNotEmpty) {
      request.fields['ingredients_text_from_barcode'] = ingredientsTextFromBarcode.trim();
    }

    final streamed = await request.send().timeout(const Duration(seconds: 240));
    final response = await http.Response.fromStream(streamed);

print('ANALYZE STATUS: ${response.statusCode}');
print('ANALYZE BODY: ${utf8.decode(response.bodyBytes)}');

if (response.statusCode < 200 || response.statusCode >= 300) {
  throw Exception(
    'Analiz servisi hata verdi: ${response.statusCode} - ${response.body}',
  );
}

final json = jsonDecode(utf8.decode(response.bodyBytes))
    as Map<String, dynamic>;

return AnalysisResult.fromJson(json);
  }
}
