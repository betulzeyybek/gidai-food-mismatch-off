import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/analysis_result.dart';

class SavedImagesService {
  static const _baseKey = 'saved_images';

  static String _getUserKey() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Kullanıcı oturumu bulunamadı.');
    }

    return '${_baseKey}_${user.uid}';
  }

  static Future<String> _copyToAppFolder(
    String sourcePath,
    String prefix,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Görsel kaydetmek için giriş yapılmış olmalı.');
    }

    final docs = await getApplicationDocumentsDirectory();
    final savedDir = Directory('${docs.path}/saved_images/${user.uid}');

    if (!await savedDir.exists()) {
      await savedDir.create(recursive: true);
    }

    final ext = _safeExt(sourcePath);
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final newPath = '${savedDir.path}/$fileName';

    await File(sourcePath).copy(newPath);

    return newPath;
  }

  static Future<String> saveToAppFolder(
    String sourcePath, {
    AnalysisResult? analysisResult,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Görsel kaydetmek için giriş yapılmış olmalı.');
    }

    final newPath = await _copyToAppFolder(sourcePath, 'scan');

    final prefs = await SharedPreferences.getInstance();
    final key = _getUserKey();
    final list = prefs.getStringList(key) ?? [];

    list.insert(
      0,
      jsonEncode({
        'path': newPath,
        'frontImagePath': newPath,
        'ingredientsImagePath': null,
        'createdAt': DateTime.now().toIso8601String(),
        'userId': user.uid,
        'email': user.email,
        'isFavorite': false,
        'productName': analysisResult?.productName,
        'misleadingScore': analysisResult?.misleadingScore,
        'detectedVisuals': analysisResult?.detectedVisuals,
        'actualIngredients': analysisResult?.actualIngredients,
        'healthRisk': analysisResult?.healthRisk,
        'healthScore': analysisResult?.healthScore,
        'eCodes': analysisResult?.eCodes,
        'mismatches': analysisResult?.mismatches,
        'explanation': analysisResult?.explanation,
        'ocrSource': analysisResult?.ocrSource,
        'dataSource': analysisResult?.dataSource,
      }),
    );

    await prefs.setStringList(key, list);

    return newPath;
  }

  static Future<String> saveVisualAnalysisImages({
    required String frontImagePath,
    required String ingredientsImagePath,
    AnalysisResult? analysisResult,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Görsel kaydetmek için giriş yapılmış olmalı.');
    }

    final savedFrontPath = await _copyToAppFolder(frontImagePath, 'front');
    final savedIngredientsPath =
        await _copyToAppFolder(ingredientsImagePath, 'ingredients');

    final prefs = await SharedPreferences.getInstance();
    final key = _getUserKey();
    final list = prefs.getStringList(key) ?? [];

    list.insert(
      0,
      jsonEncode({
        'path': savedFrontPath,
        'frontImagePath': savedFrontPath,
        'ingredientsImagePath': savedIngredientsPath,
        'createdAt': DateTime.now().toIso8601String(),
        'userId': user.uid,
        'email': user.email,
        'isFavorite': false,
        'productName': analysisResult?.productName,
        'misleadingScore': analysisResult?.misleadingScore,
        'detectedVisuals': analysisResult?.detectedVisuals,
        'actualIngredients': analysisResult?.actualIngredients,
        'healthRisk': analysisResult?.healthRisk,
        'healthScore': analysisResult?.healthScore,
        'eCodes': analysisResult?.eCodes,
        'mismatches': analysisResult?.mismatches,
        'explanation': analysisResult?.explanation,
        'ocrSource': analysisResult?.ocrSource,
        'dataSource': analysisResult?.dataSource,
      }),
    );

    await prefs.setStringList(key, list);

    return savedFrontPath;
  }

  static Future<void> saveBarcodeAnalysis({
    required String barcode,
    required AnalysisResult analysisResult,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Analizi kaydetmek için giriş yapılmış olmalı.');
    }

    final prefs = await SharedPreferences.getInstance();
    final key = _getUserKey();
    final list = prefs.getStringList(key) ?? [];

    list.insert(
      0,
      jsonEncode({
        'path': null,
        'frontImagePath': null,
        'ingredientsImagePath': null,
        'barcode': barcode,
        'createdAt': DateTime.now().toIso8601String(),
        'userId': user.uid,
        'email': user.email,
        'isFavorite': false,
        'productName': analysisResult.productName,
        'misleadingScore': analysisResult.misleadingScore,
        'detectedVisuals': analysisResult.detectedVisuals,
        'actualIngredients': analysisResult.actualIngredients,
        'healthRisk': analysisResult.healthRisk,
        'healthScore': analysisResult.healthScore,
        'eCodes': analysisResult.eCodes,
        'mismatches': analysisResult.mismatches,
        'explanation': analysisResult.explanation,
        'ocrSource': analysisResult.ocrSource,
        'dataSource': analysisResult.dataSource,
        'imageUrl': analysisResult.imageUrl,
        'image_url': analysisResult.imageUrl,
      }),
    );

    await prefs.setStringList(key, list);
  }

  static Future<List<Map<String, dynamic>>> getSavedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getUserKey();
    final list = prefs.getStringList(key) ?? [];

    return list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<List<String>> getSavedPaths() async {
    final items = await getSavedItems();
    return items.map((m) => m['path'] as String).toList();
  }

  static Future<void> updateAnalysisByPath(
    String path,
    AnalysisResult analysisResult,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getUserKey();
    final list = prefs.getStringList(key) ?? [];

    final updatedList = list.map((e) {
      final m = jsonDecode(e) as Map<String, dynamic>;

      if (m['path'] == path || m['frontImagePath'] == path) {
        m['productName'] = analysisResult.productName;
        m['misleadingScore'] = analysisResult.misleadingScore;
        m['detectedVisuals'] = analysisResult.detectedVisuals;
        m['actualIngredients'] = analysisResult.actualIngredients;
        m['healthRisk'] = analysisResult.healthRisk;
        m['healthScore'] = analysisResult.healthScore;
        m['eCodes'] = analysisResult.eCodes;
        m['mismatches'] = analysisResult.mismatches;
        m['explanation'] = analysisResult.explanation;
        m['ocrSource'] = analysisResult.ocrSource;
        m['dataSource'] = analysisResult.dataSource;
        m['imageUrl'] = analysisResult.imageUrl;
        m['image_url'] = analysisResult.imageUrl;

        m['isFavorite'] = m['isFavorite'] ?? false;
      }

      return jsonEncode(m);
    }).toList();

    await prefs.setStringList(key, updatedList);
  }


  static Future<Map<String, dynamic>?> getSavedItemByPath(String path) async {
  final items = await getSavedItems();

  for (final item in items) {
    if (item['path'] == path || item['frontImagePath'] == path) {
      return item;
    }
  }

  return null;
}

  static Future<void> toggleFavorite(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getUserKey();
    final list = prefs.getStringList(key) ?? [];

    final updatedList = list.map((e) {
      final m = jsonDecode(e) as Map<String, dynamic>;

      if (m['path'] == path || m['frontImagePath'] == path) {
        final current = m['isFavorite'] == true;
        m['isFavorite'] = !current;
      }

      return jsonEncode(m);
    }).toList();

    await prefs.setStringList(key, updatedList);
  }

  static Future<bool> isFavorite(String path) async {
    final items = await getSavedItems();

    for (final item in items) {
      if (item['path'] == path || item['frontImagePath'] == path) {
        return item['isFavorite'] == true;
      }
    }

    return false;
  }

  static Future<void> deleteSavedPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getUserKey();
    final list = prefs.getStringList(key) ?? [];

    Map<String, dynamic>? selectedItem;

    for (final e in list) {
      final m = jsonDecode(e) as Map<String, dynamic>;
      if (m['path'] == path || m['frontImagePath'] == path) {
        selectedItem = m;
        break;
      }
    }

    if (selectedItem != null) {
      final frontPath = selectedItem['frontImagePath'] as String?;
      final ingredientsPath = selectedItem['ingredientsImagePath'] as String?;

      if (frontPath != null) {
        final frontFile = File(frontPath);
        if (await frontFile.exists()) {
          await frontFile.delete();
        }
      }

      if (ingredientsPath != null) {
        final ingredientsFile = File(ingredientsPath);
        if (await ingredientsFile.exists()) {
          await ingredientsFile.delete();
        }
      }
    } else {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    list.removeWhere((e) {
      final m = jsonDecode(e) as Map<String, dynamic>;
      return m['path'] == path || m['frontImagePath'] == path;
    });

    await prefs.setStringList(key, list);
  }

  static String _safeExt(String path) {
    final parts = path.split('.');
    if (parts.length < 2) return 'jpg';

    final ext = parts.last.toLowerCase();
    return ext.isEmpty ? 'jpg' : ext;
  }
}
