class AnalysisResult {
  final String productName;
  final int misleadingScore;
  final String mismatchLevel;
  final List<String> detectedVisuals;
  final List<String> actualIngredients;
  final String healthRisk;
  final int healthScore;
  final String healthSummary;
  final List<String> healthReasons;
  final List<String> eCodes;
  final List<String> mismatches;
  final String explanation;
  final String ocrSource;
  final String dataSource;
  final String? imageUrl;

  final List<String> allergens;
  final List<String> allergenContains;
  final List<String> allergenMayContain;
  final String allergenLevel;
  final String allergenSummary;
  final String allergenDisclaimer;

  AnalysisResult({
    required this.productName,
    required this.misleadingScore,
    this.mismatchLevel = 'hesaplanmadı',
    required this.detectedVisuals,
    required this.actualIngredients,
    required this.healthRisk,
    this.healthScore = 0,
    this.healthSummary = '',
    this.healthReasons = const [],
    this.eCodes = const [],
    this.mismatches = const [],
    this.explanation = '',
    this.ocrSource = 'backend',
    this.dataSource = 'backend',
    this.imageUrl,
    this.allergens = const [],
    this.allergenContains = const [],
    this.allergenMayContain = const [],
    this.allergenLevel = '',
    this.allergenSummary = '',
    this.allergenDisclaimer = '',
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    List<String> asStringList(dynamic value) {
      if (value is List) {
        return value
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList();
      }

      if (value is String && value.trim().isNotEmpty) {
        return [value.trim()];
      }

      return const [];
    }

    int asInt(dynamic value) {
      if (value is num) {
        return value.round();
      }

      return int.tryParse((value ?? '0').toString()) ?? 0;
    }

    Map<String, dynamic> asMap(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value;
      }

      if (value is Map) {
        return value.map(
          (key, val) => MapEntry(key.toString(), val),
        );
      }

      return <String, dynamic>{};
    }

    List<String> cleanIngredientList(dynamic value) {
      final text = (value ?? '').toString().trim();

      if (text.isEmpty) {
        return const [];
      }

      var cleaned = text
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('(', ' ')
          .replaceAll(')', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final cutWords = [
        'enerji',
        'besin',
        'nutrition',
        'hazırlanışı',
        'hazirlanişi',
        'hazirlanisi',
        'tavsiye edilen',
        'parti no',
        'bilmenizde',
        'afiyet olsun',
      ];

      final lower = cleaned.toLowerCase();

      for (final word in cutWords) {
        final index = lower.indexOf(word);
        if (index > 20) {
          cleaned = cleaned.substring(0, index).trim();
          break;
        }
      }

      final parts = cleaned
          .split(RegExp(r'[,;]'))
          .map((e) => e.trim())
          .where((e) {
            if (e.length < 2) return false;

            final lowerItem = e.toLowerCase();

            final badStarts = [
              '100g',
              '100 g',
              '1 porsiyon',
              'enerji',
              'hazırlanışı',
              'hazirlanisi',
              'bilmenizde',
              'tavsiye',
              'parti',
              'afiyet',
            ];

            return !badStarts.any((bad) => lowerItem.startsWith(bad));
          })
          .toList();

      if (parts.isEmpty) {
        return [cleaned];
      }

      return parts.take(8).toList();
    }

    List<String> visualIngredientsFromMap(dynamic value) {
      final map = asMap(value);
      final found = <String>[];

      map.forEach((key, val) {
        final list = asStringList(val);

        if (list.isNotEmpty) {
          found.add(key.toString());
        }
      });

      return found;
    }

    final ocr = asMap(json['ocr']);
    final ingredientAnalysis = asMap(json['ingredient_analysis']);
    final healthScoreJson = asMap(json['health_score']);
    final mismatchScoreJson = asMap(json['mismatch_score']);
    final allergenJson = asMap(json['allergen_analysis']);

    final productName =
        json['product_name'] ??
        json['productName'] ??
        'Analiz Edilen Ürün';

    final image =
        json['image_url'] ??
        json['imageUrl'] ??
        json['front_image_url'] ??
        json['frontImageUrl'];

    final mismatchScoreValue =
        mismatchScoreJson['score'] ??
        json['misleading_score'] ??
        json['misleadingScore'] ??
        0;

    final mismatchLevelValue =
        mismatchScoreJson['level'] ??
        json['mismatch_level'] ??
        json['mismatchLevel'] ??
        'hesaplanmadı';

    final detectedVisuals = asStringList(
      mismatchScoreJson['detected_visuals'] ??
          json['visual_claims'] ??
          json['detectedVisuals'],
    );

    final matchedIngredients = asStringList(
      mismatchScoreJson['matched_ingredients'],
    );

    final missingIngredients = asStringList(
      mismatchScoreJson['missing_ingredients'],
    );

    final visualIngredients = visualIngredientsFromMap(
      ingredientAnalysis['visual_related_ingredients'],
    );

    final ingredientsFromText = cleanIngredientList(
      ingredientAnalysis['cleaned_text'] ?? json['ingredients'],
    );

    final riskKeywords = asStringList(
      ingredientAnalysis['risk_keywords'],
    );

    final aromaTerms = asStringList(
      ingredientAnalysis['aroma_terms'],
    );

    final actualIngredients = <String>[
      ...ingredientsFromText,
    ];

    if (actualIngredients.isEmpty) {
      actualIngredients.addAll(riskKeywords);
    }

    if (actualIngredients.isEmpty) {
      actualIngredients.addAll(aromaTerms);
    }

    if (actualIngredients.isEmpty) {
      actualIngredients.addAll(visualIngredients);
    }

    if (actualIngredients.isEmpty) {
      actualIngredients.add('İçerik bilgisi okunamadı');
    }

    final healthRiskLevel =
        healthScoreJson['risk_level'] ??
        json['health_risk_level'] ??
        json['healthRisk'] ??
        json['health_risk'] ??
        'bilinmiyor';

    final healthScoreValue =
        healthScoreJson['score'] ??
        json['healthScore'] ??
        json['health_score_value'] ??
        0;

    final healthSummary =
        healthScoreJson['summary'] ??
        json['health_summary'] ??
        '';

    final healthReasons = asStringList(
      healthScoreJson['reasons'],
    );

    final nutritionReasons = asStringList(
      healthScoreJson['nutrition_reasons'],
    );

    final eCodes = asStringList(
      ingredientAnalysis['e_codes'] ??
          json['e_codes'] ??
          json['eCodes'],
    );

    final mismatchReasons = asStringList(
      mismatchScoreJson['reasons'] ?? json['mismatches'],
    );

    final mismatches = <String>[
      ...mismatchReasons,
    ];

    if (missingIngredients.isNotEmpty) {
      mismatches.add(
        'İçerikte karşılığı bulunamayan görseller: ${missingIngredients.join(", ")}',
      );
    }

    if (matchedIngredients.isNotEmpty && mismatches.isEmpty) {
      mismatches.add(
        'İçerikte karşılığı bulunan görseller: ${matchedIngredients.join(", ")}',
      );
    }

    if (mismatches.isEmpty) {
      mismatches.addAll(healthReasons.take(4));
    }

    if (mismatches.isEmpty) {
      mismatches.addAll(nutritionReasons.take(4));
    }

    final finalComment = json['final_comment'];
    final healthExplanation = healthScoreJson['explanation'];
    final mismatchExplanation = mismatchScoreJson['explanation'];

    final explanation = (
      finalComment ??
              json['explanation'] ??
              healthSummary ??
              healthExplanation ??
              mismatchExplanation ??
              ''
    ).toString();

    final ocrSource =
        ocr['source'] ??
        json['ocr_source'] ??
        json['ocrSource'] ??
        'backend';

    final dataSource =
        json['data_source'] ??
        json['dataSource'] ??
        'backend';

    final allergens = asStringList(
      allergenJson['allergens'] ?? json['allergens'],
    );

    final allergenContains = asStringList(
      allergenJson['contains'] ?? json['allergen_contains'],
    );

    final allergenMayContain = asStringList(
      allergenJson['may_contain'] ?? json['allergen_may_contain'],
    );

    final allergenLevel =
        allergenJson['level'] ??
        json['allergen_level'] ??
        '';

    final allergenSummary =
        allergenJson['summary'] ??
        json['allergen_summary'] ??
        '';

    final allergenDisclaimer =
        allergenJson['disclaimer'] ??
        json['allergen_disclaimer'] ??
        '';

    return AnalysisResult(
      productName: productName.toString(),
      misleadingScore: asInt(mismatchScoreValue),
      mismatchLevel: mismatchLevelValue.toString(),
      detectedVisuals: detectedVisuals,
      actualIngredients: actualIngredients,
      healthRisk: healthRiskLevel.toString(),
      healthScore: asInt(healthScoreValue),
      healthSummary: healthSummary.toString(),
      healthReasons: healthReasons,
      eCodes: eCodes,
      mismatches: mismatches,
      explanation: explanation,
      ocrSource: ocrSource.toString(),
      dataSource: dataSource.toString(),
      imageUrl: image?.toString(),
      allergens: allergens,
      allergenContains: allergenContains,
      allergenMayContain: allergenMayContain,
      allergenLevel: allergenLevel.toString(),
      allergenSummary: allergenSummary.toString(),
      allergenDisclaimer: allergenDisclaimer.toString(),
    );
  }

  factory AnalysisResult.mock() {
    return AnalysisResult(
      productName: 'Çilekli Süt',
      misleadingScore: 75,
      mismatchLevel: 'yüksek',
      detectedVisuals: ['çilek', 'süt', 'bal'],
      actualIngredients: ['su', 'şeker', 'çilek aroması', 'E211', 'E110'],
      healthRisk: 'orta',
      healthScore: 45,
      healthSummary: 'Bu üründe bazı dikkat gerektiren içerik ifadeleri tespit edildi.',
      healthReasons: [
        'Dikkat gerektiren içerik ifadesi: şeker',
        'Dikkat gerektiren içerik ifadesi: aroma verici',
      ],
      eCodes: ['E211', 'E110'],
      mismatches: [
        'Çilek görseli var ancak gerçek çilek yerine aroma ifadesi bulunuyor.',
      ],
      explanation:
          'Ambalajda doğal çilek algısı oluşuyor; içerikte ise gerçek çilek yerine aroma kullanımı görülüyor.',
      ocrSource: 'mock',
      dataSource: 'demo',
      imageUrl: null,
      allergens: ['süt', 'soya'],
      allergenContains: ['süt'],
      allergenMayContain: ['soya'],
      allergenLevel: 'uyarı',
      allergenSummary:
          'Bu üründe süt alerjeni tespit edildi. Ayrıca soya içerebileceğine dair uyarı bulundu.',
      allergenDisclaimer:
          'Bu bilgi OCR ile okunan etikete dayalıdır ve tıbbi öneri değildir.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'product_name': productName,
      'misleadingScore': misleadingScore,
      'misleading_score': misleadingScore,
      'mismatchLevel': mismatchLevel,
      'mismatch_level': mismatchLevel,
      'detectedVisuals': detectedVisuals,
      'visual_claims': detectedVisuals,
      'actualIngredients': actualIngredients,
      'ingredients': actualIngredients,
      'healthRisk': healthRisk,
      'health_risk_level': healthRisk,
      'healthScore': healthScore,
      'health_score_value': healthScore,
      'healthSummary': healthSummary,
      'health_summary': healthSummary,
      'healthReasons': healthReasons,
      'health_reasons': healthReasons,
      'eCodes': eCodes,
      'e_codes': eCodes,
      'mismatches': mismatches,
      'explanation': explanation,
      'ocrSource': ocrSource,
      'ocr_source': ocrSource,
      'dataSource': dataSource,
      'data_source': dataSource,
      'imageUrl': imageUrl,
      'image_url': imageUrl,
      'allergens': allergens,
      'allergen_contains': allergenContains,
      'allergen_may_contain': allergenMayContain,
      'allergen_level': allergenLevel,
      'allergen_summary': allergenSummary,
      'allergen_disclaimer': allergenDisclaimer,
      'allergen_analysis': {
        'allergens': allergens,
        'contains': allergenContains,
        'may_contain': allergenMayContain,
        'level': allergenLevel,
        'summary': allergenSummary,
        'disclaimer': allergenDisclaimer,
      },
    };
  }
}