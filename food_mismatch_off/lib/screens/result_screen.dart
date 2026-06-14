import 'dart:io';

import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../services/saved_images_service.dart';
import 'home_screen.dart';

const _primaryLilac = Color(0xFF8E73D8);
const _softLilac = Color(0xFFF4EDFF);
const _darkText = Color(0xFF2B2146);

class ResultScreen extends StatefulWidget {
  final String? imagePath;
  final AnalysisResult? analysisResult;

  const ResultScreen({
    super.key,
    this.imagePath,
    this.analysisResult,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final AnalysisResult result;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();

    result = widget.analysisResult ??
        AnalysisResult(
          productName: 'Analiz Edilen Ürün',
          misleadingScore: 0,
          mismatchLevel: 'hesaplanmadı',
          detectedVisuals: const [],
          actualIngredients: const ['İçerik bilgisi bulunamadı'],
          healthRisk: 'bilinmiyor',
          healthScore: 0,
          healthSummary: '',
          healthReasons: const [],
          eCodes: const [],
          mismatches: const [],
          explanation: '',
          ocrSource: '',
          dataSource: '',
          allergens: const [],
          allergenContains: const [],
          allergenMayContain: const [],
          allergenLevel: '',
          allergenSummary: '',
          allergenDisclaimer: '',
        );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.imagePath != null) {
        await SavedImagesService.updateAnalysisByPath(
          widget.imagePath!,
          result,
        );

        final fav = await SavedImagesService.isFavorite(widget.imagePath!);

        if (!mounted) return;

        setState(() {
          isFavorite = fav;
        });
      }
    });
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _mainText =>
      _isDark ? const Color(0xFFF8EDFF) : const Color(0xFF2B2146);

  Color get _softText =>
      _isDark ? const Color(0xFFCABBDC) : const Color(0xFF6F6287);

  Color get _cardColor => _isDark
      ? const Color(0xFF2A203A).withValues(alpha: 0.92)
      : Colors.white.withValues(alpha: 0.92);

  Future<void> _toggleFavorite() async {
    if (widget.imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu analiz favorilere eklenemedi.'),
        ),
      );
      return;
    }

    await SavedImagesService.toggleFavorite(widget.imagePath!);

    final fav = await SavedImagesService.isFavorite(widget.imagePath!);

    if (!mounted) return;

    setState(() {
      isFavorite = fav;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          fav ? 'Favorilere eklendi' : 'Favorilerden çıkarıldı',
        ),
      ),
    );
  }

  Future<void> _goBack() async {
    final didPop = await Navigator.of(context).maybePop();

    if (!didPop && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColors = _isDark
        ? const [
            Color(0xFF181226),
            Color(0xFF241A36),
            Color(0xFF2E2144),
          ]
        : const [
            Color(0xFFFFF9FB),
            Color(0xFFF4EDFF),
            Color(0xFFFFEEF7),
          ];

    return Scaffold(
      backgroundColor: bgColors.first,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgColors,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                    decoration: BoxDecoration(
                      color: _isDark
                          ? const Color(0xFF181226).withValues(alpha: 0.96)
                          : Colors.white.withValues(alpha: 0.74),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(34),
                        topRight: Radius.circular(34),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isDark
                              ? Colors.black.withValues(alpha: 0.22)
                              : _primaryLilac.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildScoreOverviewCards(),
                        const SizedBox(height: 14),
                        if (result.explanation.isNotEmpty)
                          _buildCard(
                            title: 'Genel Değerlendirme',
                            icon: Icons.auto_awesome_rounded,
                            child: Text(
                              result.explanation,
                              style: TextStyle(
                                color: _mainText,
                                fontSize: 14,
                                height: 1.45,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (result.explanation.isNotEmpty)
                          const SizedBox(height: 14),
                        _buildAllergenCard(),
                        const SizedBox(height: 14),
                        _buildCard(
                          title: 'Ambalajda Görülenler',
                          icon: Icons.image_search_rounded,
                          child: _buildVisualsContent(),
                        ),
                        const SizedBox(height: 14),
                        _buildCard(
                          title: 'Okunan İçerik',
                          icon: Icons.receipt_long_rounded,
                          child: _buildIngredientsContent(),
                        ),
                        const SizedBox(height: 14),
                        if (result.healthReasons.isNotEmpty)
                          _buildCard(
                            title: 'Sağlık Skoru Nedenleri',
                            icon: Icons.monitor_heart_rounded,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: result.healthReasons
                                  .take(5)
                                  .map((m) => _checkRow(m))
                                  .toList(),
                            ),
                          ),
                        if (result.healthReasons.isNotEmpty)
                          const SizedBox(height: 14),
                        if (result.eCodes.isNotEmpty)
                          _buildCard(
                            title: 'Tespit Edilen E-Kodları',
                            icon: Icons.science_rounded,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: result.eCodes
                                  .map(
                                    (e) => Chip(
                                      label: Text(e),
                                      backgroundColor: _isDark
                                          ? const Color(0xFF3A2A4E)
                                          : _softLilac,
                                      labelStyle: TextStyle(
                                        color: _mainText,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        if (result.eCodes.isNotEmpty)
                          const SizedBox(height: 14),
                        if (result.mismatches.isNotEmpty)
                          _buildCard(
                            title: 'Görsel-İçerik Açıklaması',
                            icon: Icons.compare_arrows_rounded,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: result.mismatches
                                  .map((m) => _checkRow(m))
                                  .toList(),
                            ),
                          ),
                      ],
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

  Widget _buildHeader() {
    final headerColors = _isDark
        ? const [
            Color(0xFF2A203A),
            Color(0xFF3A2A4E),
            Color(0xFF56323D),
          ]
        : const [
            Color(0xFFEDE4FF),
            Color(0xFFD9C8FF),
            Color(0xFFFFEEF7),
          ];

    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: headerColors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -70,
            child: _decorCircle(
              180,
              _isDark ? const Color(0xFF4A3570) : const Color(0xFFFFF4FB),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -70,
            child: _decorCircle(
              170,
              _isDark ? const Color(0xFF56323D) : const Color(0xFFFFE0EA),
            ),
          ),
          Positioned(
            top: 18,
            left: 16,
            child: _HeaderCircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: _goBack,
              isDark: _isDark,
            ),
          ),
          Positioned(
            top: 18,
            right: 16,
            child: _FavoriteButton(
              isFavorite: isFavorite,
              onTap: _toggleFavorite,
              isDark: _isDark,
            ),
          ),
          Positioned(
            top: 28,
            left: 0,
            right: 0,
            child: Text(
              'Analiz Sonucu',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _mainText,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ),
          Positioned(
            left: 22,
            top: 106,
            right: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _cleanProductTitle(result.productName),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: _mainText,
                    height: 1.08,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Analiz tarihi:',
                  style: TextStyle(
                    color: _softText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _formattedDate(),
                  style: TextStyle(
                    color: _softText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            bottom: 18,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: _isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.46),
                borderRadius: BorderRadius.circular(30),
              ),
              child: _buildProductImage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreOverviewCards() {
    final mismatchCalculated =
        result.mismatchLevel.toLowerCase().trim() != 'hesaplanmadı';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Sağlık Dikkat Skoru',
            value: result.healthScore.clamp(0, 100).toString(),
            suffix: '%',
            label: result.healthRisk.toUpperCase(),
            color: _riskColor(result.healthRisk),
            icon: _riskIcon(result.healthRisk),
            progressValue: result.healthScore.clamp(0, 100) / 100,
            description: result.healthSummary.trim().isNotEmpty
                ? result.healthSummary.trim()
                : _riskDescription(result.healthRisk),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Yanıltıcılık Skoru',
            value: mismatchCalculated
                ? result.misleadingScore.clamp(0, 100).toString()
                : '-',
            suffix: mismatchCalculated ? '%' : '',
            label: mismatchCalculated
                ? _scoreLabel(result.misleadingScore).toUpperCase()
                : 'HESAPLANMADI',
            color: mismatchCalculated
                ? _scoreColor(result.misleadingScore)
                : (_isDark ? const Color(0xFFCABBDC) : const Color(0xFF8B7A9E)),
            icon: mismatchCalculated
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            progressValue: mismatchCalculated
                ? result.misleadingScore.clamp(0, 100) / 100
                : 0,
            description: mismatchCalculated
                ? 'Ambalaj görselleri içerik listesiyle karşılaştırıldı.'
                : 'Görsel tespit yapılmadığı için bu skor hesaplanmadı.',
            showProgress: mismatchCalculated,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String suffix,
    required String label,
    required Color color,
    required IconData icon,
    required double progressValue,
    required String description,
    bool showProgress = true,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 250,
      ),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: _mainText,
              fontSize: 15,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
              if (suffix.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 3, bottom: 4),
                  child: Text(
                    suffix,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.76),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildGaugeBar(
            value: progressValue,
            color: color,
            showProgress: showProgress,
          ),
          const SizedBox(height: 10),
          Text(
            description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _softText,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeBar({
    required double value,
    required Color color,
    required bool showProgress,
  }) {
    final clampedValue = value.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final markerLeft =
            (maxWidth * clampedValue - 9).clamp(0.0, maxWidth - 18);

        return SizedBox(
          height: 28,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 4,
                child: Container(
                  height: 9,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              if (showProgress)
                Positioned(
                  left: 0,
                  bottom: 4,
                  child: Container(
                    width: maxWidth * clampedValue,
                    height: 9,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              if (showProgress)
                Positioned(
                  left: markerLeft,
                  top: -2,
                  child: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: color,
                    size: 26,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAllergenCard() {
    final hasAllergen = result.allergens.isNotEmpty ||
        result.allergenContains.isNotEmpty ||
        result.allergenMayContain.isNotEmpty;

    final level = result.allergenLevel.toLowerCase().trim();

    final warningLevel = hasAllergen || level == 'uyarı' || level == 'yüksek';

    final color = warningLevel
        ? const Color(0xFFE2A53B)
        : (_isDark ? const Color(0xFFCABBDC) : const Color(0xFF8B7A9E));

    final title = warningLevel ? 'Alerjen Uyarısı' : 'Alerjen Bilgisi';

    final summary = result.allergenSummary.trim().isNotEmpty
        ? result.allergenSummary.trim()
        : 'Belirgin bir alerjen ifadesi tespit edilmedi. Yine de ürünü tüketmeden önce etiketi kontrol ediniz.';

    return _buildCard(
      title: title,
      icon: warningLevel
          ? Icons.warning_amber_rounded
          : Icons.verified_user_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  warningLevel
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline_rounded,
                  color: color,
                  size: 23,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    summary,
                    style: TextStyle(
                      color: _mainText,
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (result.allergens.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.allergens
                  .map(
                    (a) => Chip(
                      label: Text(a),
                      backgroundColor: color.withValues(alpha: 0.13),
                      labelStyle: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Bu değerlendirme ürün etiketinden alınan bilgilere dayalıdır ve tıbbi öneri değildir. Ciddi alerjilerde ürünü tüketmeden önce resmi ürün etiketi dikkatle kontrol edilmelidir.',
            style: TextStyle(
              color: _softText,
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: _isDark ? 0.35 : 0.55),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildProductImage() {
    if (widget.imagePath != null && File(widget.imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.file(
          File(widget.imagePath!),
          fit: BoxFit.cover,
        ),
      );
    }

    if (result.imageUrl != null && result.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.network(
          result.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.image_rounded,
            color: _primaryLilac,
            size: 62,
          ),
        ),
      );
    }

    return const Icon(
      Icons.image_rounded,
      color: _primaryLilac,
      size: 62,
    );
  }

  Widget _buildVisualsContent() {
    if (result.detectedVisuals.isEmpty) {
      return Text(
        'Ambalaj üzerinde belirgin bir görsel unsur tespit edilemedi.',
        style: TextStyle(
          color: _softText,
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _visualEmojis(result.detectedVisuals),
        ),
        const SizedBox(height: 10),
        ...result.detectedVisuals.take(6).map(
              (v) => _checkRow(v),
            ),
      ],
    );
  }

  Widget _buildIngredientsContent() {
    final ingredients = result.actualIngredients
        .where((item) => item.trim().isNotEmpty)
        .take(8)
        .toList();

    if (ingredients.isEmpty) {
      return Text(
        'İçerik bilgisi okunamadı.',
        style: TextStyle(
          color: _softText,
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ingredients.map((i) => _checkRow(i)).toList(),
    );
  }

  Widget _buildCard({
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _primaryLilac.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: _primaryLilac,
                  ),
                ),
                const SizedBox(width: 9),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: _mainText,
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({required double radius}) {
    return BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: _isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.82),
      ),
      boxShadow: [
        BoxShadow(
          color: _isDark
              ? Colors.black.withValues(alpha: 0.22)
              : _primaryLilac.withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _checkRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 17,
            color: _primaryLilac,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: _mainText,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _visualEmojis(List<String> visuals) {
    final emojiMap = <String, String>{
      'süt': '🥛',
      'sut': '🥛',
      'çilek': '🍓',
      'cilek': '🍓',
      'bal': '🍯',
      'kakao': '🍫',
      'çikolata': '🍫',
      'cikolata': '🍫',
      'fındık': '🌰',
      'findik': '🌰',
      'üzüm': '🍇',
      'uzum': '🍇',
      'limon': '🍋',
      'portakal': '🍊',
      'yulaf': '🌾',
      'buğday': '🌾',
      'bugday': '🌾',
    };

    return visuals.map((visual) {
      final key = visual.toLowerCase().trim();
      final emoji = emojiMap[key] ?? '🍽️';

      return Text(
        emoji,
        style: const TextStyle(fontSize: 24),
      );
    }).toList();
  }

  String _formattedDate() {
    final now = DateTime.now();
    return '${now.day}.${now.month}.${now.year}';
  }

  String _cleanProductTitle(String title) {
    final cleaned = title
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('NESTL ', 'NESTLÉ ')
        .replaceAll('DO g', '')
        .replaceAll('100g', '')
        .trim();

    if (cleaned.length < 3) {
      return 'Analiz Edilen Ürün';
    }

    return cleaned;
  }

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'düşük':
        return const Color(0xFF65B891);
      case 'orta':
        return const Color(0xFFE2A53B);
      case 'yüksek':
        return const Color(0xFFD95C5C);
      default:
        return _isDark ? const Color(0xFFCABBDC) : Colors.grey;
    }
  }

  IconData _riskIcon(String risk) {
    switch (risk.toLowerCase()) {
      case 'düşük':
        return Icons.check_circle_rounded;
      case 'orta':
        return Icons.warning_amber_rounded;
      case 'yüksek':
        return Icons.error_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _scoreColor(int score) {
    if (score >= 70) {
      return const Color(0xFFD95C5C);
    }

    if (score >= 40) {
      return const Color(0xFFE2A53B);
    }

    return const Color(0xFF65B891);
  }

  String _scoreLabel(int score) {
    if (score >= 70) return 'Yüksek';
    if (score >= 40) return 'Orta';
    return 'Düşük';
  }

  String _riskDescription(String risk) {
    switch (risk.toLowerCase()) {
      case 'düşük':
        return 'Düşük düzeyde dikkat gerektiren içerik veya besin değeri sinyalleri tespit edildi.';
      case 'orta':
        return 'Bazı içerik veya besin değeri sinyalleri dikkat gerektirebilir.';
      case 'yüksek':
        return 'Yüksek dikkat gerektiren içerik veya besin değeri sinyalleri tespit edildi.';
      default:
        return 'Risk seviyesi değerlendirilemedi.';
    }
  }
}

class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _HeaderCircleButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        child: Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2A203A).withValues(alpha: 0.90)
                : Colors.white.withValues(alpha: 0.78),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.24)
                    : _primaryLilac.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isDark
                ? const Color(0xFFF8EDFF)
                : _darkText.withValues(alpha: 0.8),
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  final bool isDark;

  const _FavoriteButton({
    required this.isFavorite,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A203A).withValues(alpha: 0.90)
            : Colors.white.withValues(alpha: 0.78),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.24)
                : _primaryLilac.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isFavorite ? const Color(0xFFE8578A) : _primaryLilac,
          size: 28,
        ),
      ),
    );
  }
}