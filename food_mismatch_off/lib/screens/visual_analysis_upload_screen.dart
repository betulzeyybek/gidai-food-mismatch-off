import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/saved_images_service.dart';
import 'analysis_loading_screen.dart';

class VisualAnalysisUploadScreen extends StatefulWidget {
  final String? barcode;
  final String? productName;
  final String? ingredientsTextFromBarcode;

  const VisualAnalysisUploadScreen({
    super.key,
    this.barcode,
    this.productName,
    this.ingredientsTextFromBarcode,
  });

  @override
  State<VisualAnalysisUploadScreen> createState() =>
      _VisualAnalysisUploadScreenState();
}

class _VisualAnalysisUploadScreenState
    extends State<VisualAnalysisUploadScreen> {
  File? frontImage;
  File? ingredientsImage;

  bool isAnalyzing = false;

  final picker = ImagePicker();

  static const Color primaryLilac = Color(0xFF8E73D8);
  static const Color darkLilac = Color(0xFF2B2146);
  static const Color softLilac = Color(0xFFF3EDFF);
  static const Color mediumLilac = Color(0xFFD7B6FF);

  bool get isBarcodeFlow =>
      widget.barcode != null && widget.barcode!.trim().isNotEmpty;

  Future<void> _pickImage(bool isFront) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            const SizedBox(height: 18),
            _BottomSheetOption(
              icon: Icons.camera_alt_rounded,
              title: 'Kamera ile çek',
              subtitle: 'Ürünün fotoğrafını hemen çek',
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 12),
            _BottomSheetOption(
              icon: Icons.photo_library_rounded,
              title: 'Galeriden seç',
              subtitle: 'Daha önce çektiğin fotoğrafı yükle',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 88,
    );

    if (picked == null) return;

    setState(() {
      if (isFront) {
        frontImage = File(picked.path);
      } else {
        ingredientsImage = File(picked.path);
      }
    });
  }

  Future<void> _startAnalysis() async {
    if (isAnalyzing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analiz zaten başlatıldı, lütfen bekleyin'),
        ),
      );
      return;
    }

    if (frontImage == null || ingredientsImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen ön yüz ve içindekiler fotoğrafını ekleyin'),
        ),
      );
      return;
    }

    setState(() {
      isAnalyzing = true;
    });

    try {
      final savedPath = await SavedImagesService.saveVisualAnalysisImages(
        frontImagePath: frontImage!.path,
        ingredientsImagePath: ingredientsImage!.path,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisLoadingScreen(
            imagePath: savedPath,
            barcode: widget.barcode,
            productName: widget.productName,
            ingredientsTextFromBarcode: widget.ingredientsTextFromBarcode,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analiz başlatılırken hata oluştu: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = isBarcodeFlow ? 'Barkod Analizi' : 'Ürün Görsellerini Yükle';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFC),
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 18, 0),
                child: Row(
                  children: [
                    _TopCircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: darkLilac,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 58),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                  child: Column(
                    children: [
                      if (isBarcodeFlow) ...[
                        _BarcodeInfoCard(
                          barcode: widget.barcode!,
                          productName: widget.productName,
                        ),
                        const SizedBox(height: 18),
                      ],
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: softLilac.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: primaryLilac.withValues(alpha: 0.14),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryLilac.withValues(alpha: 0.07),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: primaryLilac,
                              size: 34,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isBarcodeFlow
                                    ? 'Barkod bilgisi alındı. Yanıltıcılık skorunun hesaplanması için ürünün ön yüzü ve içindekiler fotoğrafını da ekleyin.'
                                    : 'Analiz için ürünün ön yüzü ve içindekiler bölümünün fotoğraflarını yüklemeniz gerekiyor.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  height: 1.35,
                                  fontSize: 15,
                                  color: darkLilac,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _UploadCard(
                        number: '1',
                        title: 'Ön Yüz Fotoğrafı',
                        subtitle:
                            'Ambalajın ön tarafını örnekteki gibi net şekilde çekiniz.',
                        image: frontImage,
                        placeholderIcon: Icons.camera_alt_rounded,
                        sampleAsset: 'assets/images/front_sample.png',
                        onTap: () => _pickImage(true),
                      ),
                      const SizedBox(height: 18),
                      _UploadCard(
                        number: '2',
                        title: 'İçindekiler Fotoğrafı',
                        subtitle:
                            'İçindekiler bölümünü örnekteki gibi yakın ve okunaklı çekiniz.',
                        image: ingredientsImage,
                        placeholderIcon: Icons.camera_alt_rounded,
                        sampleAsset: 'assets/images/ingredients_sample.png',
                        onTap: () => _pickImage(false),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4DF),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFFFE4A8),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              color: Color(0xFFB98516),
                              size: 30,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Net ve okunaklı fotoğraflar daha doğru analiz sonuçları sağlar.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: darkLilac,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      GestureDetector(
                        onTap: isAnalyzing ? null : _startAnalysis,
                        child: Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                mediumLilac,
                                primaryLilac,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryLilac.withValues(alpha: 0.28),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: isAnalyzing
                                ? const SizedBox(
                                    width: 25,
                                    height: 25,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.search_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        isBarcodeFlow
                                            ? 'Barkodlu Analizi Başlat'
                                            : 'Analizi Başlat',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 21,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
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
    );
  }
}

class _BarcodeInfoCard extends StatelessWidget {
  final String barcode;
  final String? productName;

  const _BarcodeInfoCard({
    required this.barcode,
    this.productName,
  });

  static const Color primaryLilac = Color(0xFF8E73D8);
  static const Color darkLilac = Color(0xFF2B2146);

  @override
  Widget build(BuildContext context) {
    final name = productName?.trim().isNotEmpty == true
        ? productName!.trim()
        : 'Barkod ile bulunan ürün';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primaryLilac.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryLilac.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF2ECFF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              color: primaryLilac,
              size: 30,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: darkLilac,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Barkod: $barcode',
                  style: TextStyle(
                    color: darkLilac.withValues(alpha: 0.62),
                    fontSize: 13,
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
}

class _TopCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E73D8).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: const Color(0xFF6F61A8),
          size: 28,
        ),
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final File? image;
  final IconData placeholderIcon;
  final String sampleAsset;
  final VoidCallback onTap;

  const _UploadCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.placeholderIcon,
    required this.sampleAsset,
    required this.onTap,
  });

  static const Color primaryLilac = Color(0xFF8E73D8);
  static const Color darkLilac = Color(0xFF2B2146);
  static const Color mediumLilac = Color(0xFFD7B6FF);

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryLilac.withValues(alpha: 0.09),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
        border: Border.all(
          color: primaryLilac.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      mediumLilac,
                      primaryLilac,
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: darkLilac,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: darkLilac.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SampleImageBox(assetPath: sampleAsset),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickImageBox(
                  image: image,
                  placeholderIcon: placeholderIcon,
                  hasImage: hasImage,
                  onTap: onTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SampleImageBox extends StatelessWidget {
  final String assetPath;

  const _SampleImageBox({
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFFF8EEF1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _PickImageBox extends StatelessWidget {
  final File? image;
  final IconData placeholderIcon;
  final bool hasImage;
  final VoidCallback onTap;

  const _PickImageBox({
    required this.image,
    required this.placeholderIcon,
    required this.hasImage,
    required this.onTap,
  });

  static const Color primaryLilac = Color(0xFF8E73D8);
  static const Color darkLilac = Color(0xFF2B2146);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F2FF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: primaryLilac.withValues(alpha: 0.45),
            width: 1.6,
          ),
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.file(
                  image!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    placeholderIcon,
                    size: 40,
                    color: primaryLilac,
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Fotoğraf Ekle',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primaryLilac,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'veya galeriden seç',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: darkLilac.withValues(alpha: 0.65),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BottomSheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BottomSheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryLilac = Color(0xFF8E73D8);
    const darkLilac = Color(0xFF2B2146);

    return Material(
      color: Colors.white.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2ECFF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: primaryLilac,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: darkLilac,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: darkLilac.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: primaryLilac,
              ),
            ],
          ),
        ),
      ),
    );
  }
}