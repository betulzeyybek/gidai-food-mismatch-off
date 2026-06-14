import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/analysis_result.dart';
import '../services/api_service.dart';
import '../services/saved_images_service.dart';
import 'result_screen.dart';
import 'visual_analysis_upload_screen.dart';

class BarcodeSearchScreen extends StatefulWidget {
  const BarcodeSearchScreen({super.key});

  @override
  State<BarcodeSearchScreen> createState() => _BarcodeSearchScreenState();
}

class _BarcodeSearchScreenState extends State<BarcodeSearchScreen> {
  final TextEditingController barcodeController = TextEditingController();

  bool isLoading = false;
  bool isAnalyzing = false;
  Map<String, dynamic>? product;

  final Color lilac = const Color(0xFFB99BE5);
  final Color salmon = const Color(0xFFF2A39A);
  final Color mint = const Color(0xFF79B89A);

  @override
  void dispose() {
    barcodeController.dispose();
    super.dispose();
  }

  Future<void> searchBarcode() async {
    final barcode = barcodeController.text.trim();

    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen barkod numarası girin')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      product = null;
    });

    try {
      final result = await ApiService.getProductByBarcode(barcode);

      if (!mounted) return;

      setState(() {
        product = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        product = {
          'found': false,
          'product_name': 'Ürün bulunamadı',
          'message':
              'Bu barkod için ürün bilgisi bulunamadı. Fotoğrafla tam analiz yapabilirsiniz.',
        };
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ürün bulunamadı. Fotoğrafla analiz yapabilirsiniz.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> analyzeBarcode() async {
    final barcode = barcodeController.text.trim();

    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen barkod numarası girin')),
      );
      return;
    }

    final imageUrl = product?['image_url']?.toString() ??
        product?['front_image_url']?.toString();

    final hasOpenFoodFactsImage =
        imageUrl != null && imageUrl.trim().isNotEmpty;

    if (!hasOpenFoodFactsImage) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VisualAnalysisUploadScreen(
            barcode: barcode,
            productName: product?['product_name']?.toString(),
            ingredientsTextFromBarcode:
                product?['analysis_text']?.toString().trim().isNotEmpty == true
                    ? product!['analysis_text'].toString()
                    : product?['ingredients_text']?.toString(),
          ),
        ),
      );
      return;
    }

    setState(() {
      isAnalyzing = true;
    });

    try {
      final AnalysisResult result = await ApiService.analyzeBarcode(barcode);

      try {
        await SavedImagesService.saveBarcodeAnalysis(
          barcode: barcode,
          analysisResult: result,
        );
      } catch (saveError) {
        debugPrint('Barkod analizi kaydedilemedi: $saveError');
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            analysisResult: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Barkod analizi başarısız: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isAnalyzing = false;
        });
      }
    }
  }

  void _goPhotoAnalysis() {
    final barcode = barcodeController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisualAnalysisUploadScreen(
          barcode: barcode.isNotEmpty ? barcode : null,
          productName: product?['product_name']?.toString(),
          ingredientsTextFromBarcode:
              product?['analysis_text']?.toString().trim().isNotEmpty == true
                  ? product!['analysis_text'].toString()
                  : product?['ingredients_text']?.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mainText = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF594653);
    final softText = isDark ? const Color(0xFFCABBDC) : const Color(0xFF8D7A86);
    final cardColor = isDark
        ? const Color(0xFF2A203A).withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.78);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF181226) : const Color(0xFFFDF5FA),
      body: Stack(
        children: [
          _buildPastelBackground(isDark),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(
                    context: context,
                    isDark: isDark,
                    mainText: mainText,
                  ),
                  const SizedBox(height: 28),
                  _buildHeroCard(
                    isDark: isDark,
                    mainText: mainText,
                    softText: softText,
                    cardColor: cardColor,
                  ),
                  const SizedBox(height: 22),
                  _buildBarcodeInputCard(
                    isDark: isDark,
                    mainText: mainText,
                    softText: softText,
                    cardColor: cardColor,
                  ),
                  const SizedBox(height: 18),
                  _buildSearchButton(),
                  const SizedBox(height: 22),
                  if (product != null)
                    _ProductResultCard(
                      product: product!,
                      isAnalyzing: isAnalyzing,
                      onAnalyzeTap: analyzeBarcode,
                      onPhotoTap: _goPhotoAnalysis,
                      mainText: mainText,
                      softText: softText,
                      lilac: lilac,
                      salmon: salmon,
                      mint: mint,
                      isDark: isDark,
                    ),
                  const SizedBox(height: 22),
                  _buildInfoCard(
                    context: context,
                    isDark: isDark,
                    mainText: mainText,
                    softText: softText,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastelBackground(bool isDark) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF181226),
                      Color(0xFF241A36),
                      Color(0xFF2E2144),
                    ]
                  : const [
                      Color(0xFFFDF5FA),
                      Color(0xFFFFF8F3),
                      Color(0xFFEFE7FA),
                    ],
            ),
          ),
        ),
        Positioned(
          top: -90,
          left: -75,
          child: _blob(
            220,
            isDark ? const Color(0xFF3A2A4E) : const Color(0xFFE9DDF8),
            isDark,
          ),
        ),
        Positioned(
          top: 170,
          right: -95,
          child: _blob(
            210,
            isDark ? const Color(0xFF264738) : const Color(0xFFDFF1E9),
            isDark,
          ),
        ),
        Positioned(
          bottom: -85,
          left: -75,
          child: _blob(
            230,
            isDark ? const Color(0xFF56323D) : const Color(0xFFF8D9D2),
            isDark,
          ),
        ),
        Positioned(
          bottom: 180,
          right: -75,
          child: _blob(
            180,
            isDark ? const Color(0xFF3E2E58) : const Color(0xFFE7DDF7),
            isDark,
          ),
        ),
        Positioned(
          top: 128,
          right: 36,
          child: Icon(
            Icons.auto_awesome_rounded,
            color: lilac.withValues(alpha: isDark ? 0.35 : 0.45),
            size: 26,
          ),
        ),
        Positioned(
          top: 245,
          left: 38,
          child: Icon(
            Icons.auto_awesome_rounded,
            color: salmon.withValues(alpha: isDark ? 0.28 : 0.38),
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _blob(double size, Color color, bool isDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.35 : 0.55),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTopBar({
    required BuildContext context,
    required bool isDark,
    required Color mainText,
  }) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A203A).withValues(alpha: 0.88)
                  : Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.24)
                      : lilac.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: mainText,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'Barkodla Ara',
          style: GoogleFonts.nunito(
            color: mainText,
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard({
    required bool isDark,
    required Color mainText,
    required Color softText,
    required Color cardColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.26)
                : lilac.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          _scanLogoSmall(isDark),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ürün barkodunu gir',
                  style: GoogleFonts.nunito(
                    fontSize: 24,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: mainText,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ürün bilgisi OpenFoodFacts üzerinden sorgulanır.',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    height: 1.35,
                    color: softText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanLogoSmall(bool isDark) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? const Color(0xFF3A2A4E).withValues(alpha: 0.85)
            : const Color(0xFFEFE7FA).withValues(alpha: 0.85),
      ),
      child: Center(
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF21172F).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 25,
                height: 30,
                decoration: BoxDecoration(
                  color: lilac,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _whiteLine(13),
                    const SizedBox(height: 3),
                    _whiteLine(10),
                    const SizedBox(height: 3),
                    _whiteLine(13),
                  ],
                ),
              ),
              Positioned(top: 12, left: 12, child: _scanCorner(topLeft: true)),
              Positioned(top: 12, right: 12, child: _scanCorner(topRight: true)),
              Positioned(
                bottom: 12,
                left: 12,
                child: _scanCorner(bottomLeft: true),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: _scanCorner(bottomRight: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _whiteLine(double width) {
    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  Widget _scanCorner({
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    BorderRadius radius = BorderRadius.zero;

    if (topLeft) {
      radius = const BorderRadius.only(topLeft: Radius.circular(4));
    } else if (topRight) {
      radius = const BorderRadius.only(topRight: Radius.circular(4));
    } else if (bottomLeft) {
      radius = const BorderRadius.only(bottomLeft: Radius.circular(4));
    } else if (bottomRight) {
      radius = const BorderRadius.only(bottomRight: Radius.circular(4));
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        border: Border(
          top: topLeft || topRight
              ? BorderSide(color: lilac, width: 2.4)
              : BorderSide.none,
          bottom: bottomLeft || bottomRight
              ? BorderSide(color: lilac, width: 2.4)
              : BorderSide.none,
          left: topLeft || bottomLeft
              ? BorderSide(color: lilac, width: 2.4)
              : BorderSide.none,
          right: topRight || bottomRight
              ? BorderSide(color: lilac, width: 2.4)
              : BorderSide.none,
        ),
        borderRadius: radius,
      ),
    );
  }

  Widget _buildBarcodeInputCard({
    required bool isDark,
    required Color mainText,
    required Color softText,
    required Color cardColor,
  }) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: lilac.withValues(alpha: isDark ? 0.24 : 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.22)
                : lilac.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: TextField(
        controller: barcodeController,
        keyboardType: TextInputType.number,
        style: GoogleFonts.nunito(
          color: mainText,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          hintText: 'Barkod numarası',
          hintStyle: GoogleFonts.nunito(
            color: softText.withValues(alpha: 0.72),
            fontWeight: FontWeight.w800,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          suffixIcon: Icon(
            Icons.qr_code_scanner_rounded,
            color: mint,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFD8B7F2),
              Color(0xFFC09BE5),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: lilac.withValues(alpha: 0.32),
              blurRadius: 22,
              offset: const Offset(0, 11),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading || isAnalyzing ? null : searchBarcode,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Text(
                  'Ara',
                  style: GoogleFonts.nunito(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required bool isDark,
    required Color mainText,
    required Color softText,
  }) {
    return InkWell(
      onTap: _goPhotoAnalysis,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF264738).withValues(alpha: 0.55)
              : const Color(0xFFE2F1E9).withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.85),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.22)
                  : mint.withValues(alpha: 0.13),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Ürün fotoğrafı bulunmazsa ön yüz ve içindekiler fotoğrafını çekerek tam analiz yapabilirsin.',
                style: GoogleFonts.nunito(
                  fontSize: 14.5,
                  height: 1.35,
                  color: mainText.withValues(alpha: 0.88),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF181226).withValues(alpha: 0.65)
                    : Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.add_a_photo_rounded,
                size: 30,
                color: mint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductResultCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isAnalyzing;
  final VoidCallback onAnalyzeTap;
  final VoidCallback onPhotoTap;
  final Color mainText;
  final Color softText;
  final Color lilac;
  final Color salmon;
  final Color mint;
  final bool isDark;

  const _ProductResultCard({
    required this.product,
    required this.isAnalyzing,
    required this.onAnalyzeTap,
    required this.onPhotoTap,
    required this.mainText,
    required this.softText,
    required this.lilac,
    required this.salmon,
    required this.mint,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final found = product['found'] == true;
    final productName =
        (product['product_name'] ?? 'Ürün bulunamadı').toString();

    final brand = (
      product['brands'] ??
          product['brand'] ??
          product['brands_tags'] ??
          ''
    ).toString();

    final imageUrl = product['image_url']?.toString() ??
        product['front_image_url']?.toString();

    final hasOpenFoodFactsImage =
        imageUrl != null && imageUrl.trim().isNotEmpty;

    final message = (
      product['message'] ??
          'Ürün bilgisi bulundu. Ürün fotoğrafı varsa doğrudan analiz yapılır.'
    ).toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A203A).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.26)
                : lilac.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statusIcon(found),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  found ? productName : 'Ürün bulunamadı',
                  style: GoogleFonts.nunito(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: mainText,
                  ),
                ),
              ),
            ],
          ),
          if (brand.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Marka: $brand',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: softText,
              ),
            ),
          ],
          if (found && hasOpenFoodFactsImage) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                height: 120,
                color: isDark
                    ? const Color(0xFF181226).withValues(alpha: 0.55)
                    : const Color(0xFFF8F2FF),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.image_not_supported_rounded,
                    color: softText,
                    size: 34,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            found
                ? hasOpenFoodFactsImage
                    ? 'Ürün bilgisi ve ürün fotoğrafı bulundu. OpenFoodFacts fotoğrafı üzerinden görsel tespit yapılarak analiz sonucu oluşturulacaktır.'
                    : 'Ürün bilgisi bulundu ancak ürün fotoğrafı bulunamadı. Görsel tespit ve yanıltıcılık skoru için fotoğrafla tam analize devam edin.'
                : message,
            style: GoogleFonts.nunito(
              color: softText,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: found
                ? hasOpenFoodFactsImage
                    ? _actionButton(
                        label: isAnalyzing ? 'Analiz ediliyor...' : 'Analizi Gör',
                        icon: Icons.analytics_rounded,
                        loading: isAnalyzing,
                        onPressed: isAnalyzing ? null : onAnalyzeTap,
                      )
                    : _actionButton(
                        label: 'Fotoğrafla Tam Analize Geç',
                        icon: Icons.add_a_photo_rounded,
                        loading: false,
                        onPressed: onPhotoTap,
                      )
                : _actionButton(
                    label: 'Fotoğrafla Analize Devam Et',
                    icon: Icons.add_a_photo_rounded,
                    loading: false,
                    onPressed: onPhotoTap,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statusIcon(bool found) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: found
            ? mint.withValues(alpha: isDark ? 0.18 : 0.15)
            : salmon.withValues(alpha: isDark ? 0.18 : 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        found ? Icons.check_rounded : Icons.search_off_rounded,
        color: found ? mint : salmon,
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required bool loading,
    required VoidCallback? onPressed,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            lilac.withValues(alpha: 0.95),
            const Color(0xFFC09BE5),
          ],
        ),
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: lilac.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(19),
          ),
        ),
      ),
    );
  }
}