import 'dart:async';
import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../services/api_service.dart';
import '../services/saved_images_service.dart';
import 'result_screen.dart';

class AnalysisLoadingScreen extends StatefulWidget {
  final String imagePath;
  final String? ingredientsImagePath;

  final String? barcode;
  final String? productName;
  final String? ingredientsTextFromBarcode;

  const AnalysisLoadingScreen({
    super.key,
    required this.imagePath,
    this.ingredientsImagePath,
    this.barcode,
    this.productName,
    this.ingredientsTextFromBarcode,
  });

  @override
  State<AnalysisLoadingScreen> createState() => _AnalysisLoadingScreenState();
}

class _AnalysisLoadingScreenState extends State<AnalysisLoadingScreen> {
  int currentStep = 0;
  String? errorMessage;

  final steps = const [
    'Ön yüz görselleri Grok Vision ile analiz ediliyor...',
    'İçindekiler ve besin değerleri okunuyor...',
    'Katkı maddeleri ve alerjen bilgileri taranıyor...',
    'Görsel-içerik uyumu ve sağlık dikkat skoru hesaplanıyor...',
  ];

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    try {
      final savedItem =
          await SavedImagesService.getSavedItemByPath(widget.imagePath);

      final ingredientsPath = widget.ingredientsImagePath ??
          savedItem?['ingredientsImagePath']?.toString();

      if (ingredientsPath == null || ingredientsPath.isEmpty) {
        throw Exception('İçindekiler fotoğrafı bulunamadı.');
      }

      for (int i = 0; i < steps.length; i++) {
        await Future.delayed(const Duration(milliseconds: 420));
        if (!mounted) return;
        setState(() => currentStep = i);
      }

      final AnalysisResult result = await ApiService.analyzeProduct(
        frontImagePath: widget.imagePath,
        ingredientsImagePath: ingredientsPath,
        barcode: widget.barcode,
        productName: widget.productName,
        ingredientsTextFromBarcode: widget.ingredientsTextFromBarcode,
      );

      if (!mounted) return;

      await SavedImagesService.updateAnalysisByPath(widget.imagePath, result);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            imagePath: widget.imagePath,
            analysisResult: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = _friendlyErrorMessage(e);
      });
    }
  }

  String _friendlyErrorMessage(Object error) {
    final raw = error.toString().toLowerCase();

    if (raw.contains('socket') ||
        raw.contains('timeout') ||
        raw.contains('connection') ||
        raw.contains('failed host lookup')) {
      return 'Sunucuya bağlanırken sorun oluştu. Lütfen backend’in açık olduğundan ve telefon ile bilgisayarın aynı Wi-Fi ağına bağlı olduğundan emin olun.';
    }

    if (raw.contains('içindekiler fotoğrafı bulunamadı')) {
      return 'İçindekiler fotoğrafı bulunamadı. Lütfen geri dönüp içindekiler bölümünü tekrar ekleyin.';
    }

    if (raw.contains('ocr') || raw.contains('okunabilir metin')) {
      return 'İçindekiler fotoğrafından okunabilir metin alınamadı. Lütfen daha net ve yakın bir fotoğrafla tekrar deneyin.';
    }

    return 'Analiz tamamlanamadı. Lütfen fotoğrafları kontrol edip tekrar deneyin.';
  }

  @override
  Widget build(BuildContext context) {
    const primaryLilac = Color(0xFF8E73D8);
    const darkLilac = Color(0xFF2B2146);
    const mediumLilac = Color(0xFFD7B6FF);

    final isError = errorMessage != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FB),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF9FB),
              Color(0xFFF4EDFF),
              Color(0xFFFFEEF7),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 148,
                  height: 148,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [mediumLilac, primaryLilac],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryLilac.withValues(alpha: 0.25),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Icon(
                    isError
                        ? Icons.error_outline_rounded
                        : Icons.document_scanner_rounded,
                    size: 72,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 34),
                Text(
                  isError ? 'Analiz tamamlanamadı' : 'Analiz yapılıyor',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: darkLilac,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  errorMessage ?? steps[currentStep],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.4,
                    color: darkLilac.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 38),
                if (!isError)
                  SizedBox(
                    width: 74,
                    height: 74,
                    child: CircularProgressIndicator(
                      color: primaryLilac,
                      backgroundColor: primaryLilac.withValues(alpha: 0.14),
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Geri dön'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryLilac,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                const SizedBox(height: 34),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: primaryLilac.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    isError
                        ? 'Sorunu düzelttikten sonra tekrar analiz başlatabilirsiniz.'
                        : 'Lütfen bu ekranı kapatmayın. Sonuçlar birkaç saniye içinde hazırlanacak.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: darkLilac,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}