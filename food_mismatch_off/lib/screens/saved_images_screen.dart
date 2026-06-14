import 'dart:io';

import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../services/saved_images_service.dart';
import 'result_screen.dart';
import 'visual_analysis_upload_screen.dart';

const Color kSavedLilac = Color(0xFF8E73D8);
const Color kSavedSoftLilac = Color(0xFFC09BE5);
const Color kSavedSalmon = Color(0xFFF2A39A);

class SavedImagesScreen extends StatefulWidget {
  const SavedImagesScreen({super.key});

  @override
  State<SavedImagesScreen> createState() => _SavedImagesScreenState();
}

class _SavedImagesScreenState extends State<SavedImagesScreen> {
  late Future<List<Map<String, dynamic>>> _savedFuture;

  @override
  void initState() {
    super.initState();
    _savedFuture = SavedImagesService.getSavedItems();
  }

  void _refreshSaved() {
    setState(() {
      _savedFuture = SavedImagesService.getSavedItems();
    });
  }

  Future<void> _startFirstAnalysis() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VisualAnalysisUploadScreen(),
      ),
    );

    if (!mounted) return;
    _refreshSaved();
  }

  Future<void> _confirmDelete({
    required String title,
    required String? path,
  }) async {
    if (path == null || path.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu kayıt silinemedi: kayıt yolu bulunamadı.'),
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dialogColor = isDark
        ? const Color(0xFF2A203A)
        : Colors.white;

    final mainText = isDark
        ? const Color(0xFFF8EDFF)
        : const Color(0xFF2B2146);

    final subText = isDark
        ? const Color(0xFFCABBDC)
        : const Color(0xFF6F6287);

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 26),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            decoration: BoxDecoration(
              color: dialogColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.34)
                      : kSavedLilac.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: kSavedSalmon.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: kSavedSalmon,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Kaydı silmek istiyor musun?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mainText,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '"$title" kaydı silinecek. Bu işlem geri alınamaz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: subText,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: kSavedLilac.withValues(alpha: 0.28),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            'Vazgeç',
                            style: TextStyle(
                              color: mainText,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSavedSalmon,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Sil',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await SavedImagesService.deleteSavedPath(path);

      if (!mounted) return;

      _refreshSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt silindi')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt silinemedi: $e')),
      );
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return 'Tarih bilinmiyor';

    final date = DateTime.tryParse(iso);
    if (date == null) return 'Tarih bilinmiyor';

    return '${date.day}.${date.month}.${date.year}';
  }

  String? _asString(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColors = isDark
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

    final mainText = isDark
        ? const Color(0xFFF8EDFF)
        : const Color(0xFF2B2146);

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
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _savedFuture,
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                    child: Row(
                      children: [
                        _TopButton(
                          icon: Icons.arrow_back_rounded,
                          isDark: isDark,
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
                      children: [
                        Text(
                          'Kayıtlarım',
                          style: TextStyle(
                            fontSize: 40,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            color: mainText,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 42),
                        if (snapshot.connectionState ==
                            ConnectionState.waiting)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 80),
                              child: CircularProgressIndicator(
                                color: kSavedLilac,
                              ),
                            ),
                          )
                        else if (items.isEmpty)
                          _EmptySavedCard(
                            onStartTap: _startFirstAnalysis,
                            isDark: isDark,
                          )
                        else
                          Column(
                            children: items.map((item) {
                              final String? imagePath = _asString(
                                item['frontImagePath'] ??
                                    item['imagePath'] ??
                                    item['path'],
                              );

                              final String? imageUrl = _asString(
                                item['frontImageUrl'] ??
                                    item['imageUrl'] ??
                                    item['productImageUrl'] ??
                                    item['image_url'],
                              );

                              final String title = _asString(
                                    item['productName'] ??
                                        item['product_name'] ??
                                        item['title'],
                                  ) ??
                                  'Analiz Edilen Ürün';

                              AnalysisResult? analysisResult;

                              final dynamic rawAnalysis =
                                  item['analysisResult'] ??
                                      item['analysis_result'];

                              if (rawAnalysis is Map<String, dynamic>) {
                                analysisResult =
                                    AnalysisResult.fromJson(rawAnalysis);
                              } else if (item.containsKey('misleadingScore') ||
                                  item.containsKey('misleading_score') ||
                                  item.containsKey('productName') ||
                                  item.containsKey('product_name')) {
                                analysisResult =
                                    AnalysisResult.fromJson(item);
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _SavedItemCard(
                                  title: title,
                                  date: _formatDate(
                                    _asString(
                                      item['createdAt'] ??
                                          item['created_at'] ??
                                          item['date'],
                                    ),
                                  ),
                                  imagePath: imagePath,
                                  imageUrl: imageUrl,
                                  isDark: isDark,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ResultScreen(
                                          imagePath: imagePath,
                                          analysisResult: analysisResult,
                                        ),
                                      ),
                                    );

                                    if (!mounted) return;
                                    _refreshSaved();
                                  },
                                  onDeleteTap: () {
                                    _confirmDelete(
                                      title: title,
                                      path: imagePath,
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _TopButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark
        ? const Color(0xFF2A203A).withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.72);

    final iconColor = isDark
        ? const Color(0xFFF8EDFF)
        : const Color(0xFF6F6287);

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.24)
                : kSavedLilac.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: iconColor,
          size: 28,
        ),
      ),
    );
  }
}

class _EmptySavedCard extends StatelessWidget {
  final VoidCallback onStartTap;
  final bool isDark;

  const _EmptySavedCard({
    required this.onStartTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final mainText = isDark
        ? const Color(0xFFF8EDFF)
        : const Color(0xFF2B2146);

    final subText = isDark
        ? const Color(0xFFCABBDC)
        : const Color(0xFF6F6287);

    final cardColor = isDark
        ? const Color(0xFF2A203A).withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.78);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 42),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(38),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.70),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.28)
                : kSavedLilac.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 160,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(42),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        Color(0xFF352548),
                        Color(0xFF4A3570),
                      ]
                    : const [
                        Color(0xFFF7EFFF),
                        Color(0xFFE7D8FF),
                      ],
              ),
            ),
            child: const Icon(
              Icons.folder_rounded,
              color: Colors.white,
              size: 58,
            ),
          ),
          const SizedBox(height: 34),
          Text(
            'Henüz kayıt yok',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mainText,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Yaptığın analizler burada\nlistelenecek.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subText,
              fontSize: 18,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 34),
          GestureDetector(
            onTap: onStartTap,
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFD7B6FF),
                    Color(0xFF9B7BE8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: kSavedLilac.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'İlk analizi başlat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedItemCard extends StatelessWidget {
  final String title;
  final String date;
  final String? imagePath;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback onDeleteTap;
  final bool isDark;

  const _SavedItemCard({
    required this.title,
    required this.date,
    required this.imagePath,
    required this.imageUrl,
    required this.onTap,
    required this.onDeleteTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final file = imagePath != null ? File(imagePath!) : null;

    final cardColor = isDark
        ? const Color(0xFF2A203A).withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.82);

    final mainText = isDark
        ? const Color(0xFFF8EDFF)
        : const Color(0xFF2B2146);

    final subText = isDark
        ? const Color(0xFFCABBDC)
        : const Color(0xFF6F6287);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.70),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.24)
                : kSavedLilac.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: _SavedImagePreview(
                file: file,
                imageUrl: imageUrl,
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: mainText,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Analiz tarihi: $date',
                    style: TextStyle(
                      color: subText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onDeleteTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: kSavedSalmon.withValues(
                      alpha: isDark ? 0.16 : 0.18,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: kSavedSalmon,
                    size: 23,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 38,
                  height: 42,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: kSavedLilac,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavedImagePreview extends StatelessWidget {
  final File? file;
  final String? imageUrl;
  final bool isDark;

  const _SavedImagePreview({
    required this.file,
    required this.imageUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (file != null && file!.existsSync()) {
      return Image.file(
        file!,
        width: 78,
        height: 78,
        fit: BoxFit.cover,
      );
    }

    if (imageUrl != null && imageUrl!.startsWith('http')) {
      return Image.network(
        imageUrl!,
        width: 78,
        height: 78,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _ImagePlaceholder(isDark: isDark),
      );
    }

    return _ImagePlaceholder(isDark: isDark);
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final bool isDark;

  const _ImagePlaceholder({
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF352548),
                  Color(0xFF4A3570),
                ]
              : const [
                  Color(0xFFEDE2FF),
                  Color(0xFFF7EFFF),
                ],
        ),
      ),
      child: const Icon(
        Icons.image_rounded,
        color: kSavedLilac,
        size: 38,
      ),
    );
  }
}