import 'dart:io';
import 'package:flutter/material.dart';

import '../services/saved_images_service.dart';
import 'result_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  static const lilac = Color(0xFF8E73D8);
  static const softLilac = Color(0xFFC09BE5);
  static const pink = Color(0xFFE8578A);
  static const salmon = Color(0xFFF2A39A);

  @override
  void initState() {
    super.initState();
    _future = _loadFavorites();
  }

  Future<List<Map<String, dynamic>>> _loadFavorites() async {
    final items = await SavedImagesService.getSavedItems();
    return items.where((item) => item['isFavorite'] == true).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadFavorites();
    });
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
            Color(0xFFFFFBFC),
            Color(0xFFF4EDFF),
            Color(0xFFFFEEF7),
          ];

    final mainText = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF2B2146);
    final subText = isDark ? const Color(0xFFCABBDC) : const Color(0xFF6F6287);

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
          child: Column(
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Favoriler',
                        style: TextStyle(
                          color: mainText,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _future,
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? [];

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: softLilac,
                        ),
                      );
                    }

                    if (items.isEmpty) {
                      return _EmptyFavoritesCard(
                        isDark: isDark,
                        mainText: mainText,
                        subText: subText,
                      );
                    }

                    return RefreshIndicator(
                      color: lilac,
                      onRefresh: _refresh,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];

                          final imagePath = _asString(
                            item['frontImagePath'] ?? item['path'],
                          );

                          final imageUrl = _asString(
                            item['imageUrl'] ??
                                item['image_url'] ??
                                item['productImageUrl'],
                          );

                          final title = _asString(item['productName']) ??
                              'Analiz Edilen Ürün';

                          final score = item['misleadingScore'];
                          final risk = _asString(item['healthRisk']);

                          return _FavoriteItemCard(
                            title: title,
                            score: score,
                            risk: risk,
                            imagePath: imagePath,
                            imageUrl: imageUrl,
                            isDark: isDark,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ResultScreen(
                                    imagePath: imagePath,
                                  ),
                                ),
                              );

                              if (!mounted) return;
                              _refresh();
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
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

    final iconColor = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF6F6287);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.24)
                : const Color(0xFF8E73D8).withValues(alpha: 0.08),
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

class _EmptyFavoritesCard extends StatelessWidget {
  final bool isDark;
  final Color mainText;
  final Color subText;

  const _EmptyFavoritesCard({
    required this.isDark,
    required this.mainText,
    required this.subText,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? const Color(0xFF2A203A).withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.78);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 42, 24, 38),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.70),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.28)
                    : const Color(0xFF8E73D8).withValues(alpha: 0.10),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [
                            Color(0xFF352548),
                            Color(0xFF4A3570),
                          ]
                        : const [
                            Color(0xFFFFE8F0),
                            Color(0xFFEDE4FF),
                          ],
                  ),
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  color: Color(0xFFE8578A),
                  size: 58,
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'Henüz favori ürün yok',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mainText,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Beğendiğin analizleri favorilere eklediğinde burada görünecek.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: subText,
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteItemCard extends StatelessWidget {
  final String title;
  final dynamic score;
  final String? risk;
  final String? imagePath;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool isDark;

  const _FavoriteItemCard({
    required this.title,
    required this.score,
    required this.risk,
    required this.imagePath,
    required this.imageUrl,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final file = imagePath != null ? File(imagePath!) : null;

    final cardColor = isDark
        ? const Color(0xFF2A203A).withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.86);

    final mainText = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF2B2146);
    final subText = isDark ? const Color(0xFFCABBDC) : const Color(0xFF6F6287);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
                  : const Color(0xFF8E73D8).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: _FavoriteImagePreview(
                file: file,
                imageUrl: imageUrl,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: mainText,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      if (score != null)
                        Flexible(
                          child: Text(
                            'Skor: $score',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: subText,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (score != null && risk != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '•',
                            style: TextStyle(
                              color: subText,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      if (risk != null)
                        Flexible(
                          child: Text(
                            risk!.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _riskColor(risk!, isDark),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFE8578A).withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFE8578A),
                size: 25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _riskColor(String risk, bool isDark) {
    switch (risk.toLowerCase()) {
      case 'düşük':
        return isDark ? const Color(0xFF9ADBB8) : const Color(0xFF4C9B72);
      case 'orta':
        return isDark ? const Color(0xFFE6C27A) : const Color(0xFFD28A17);
      case 'yüksek':
        return isDark ? const Color(0xFFF2A39A) : const Color(0xFFD85B6B);
      default:
        return isDark ? const Color(0xFFCABBDC) : const Color(0xFF8D7A86);
    }
  }
}

class _FavoriteImagePreview extends StatelessWidget {
  final File? file;
  final String? imageUrl;
  final bool isDark;

  const _FavoriteImagePreview({
    required this.file,
    required this.imageUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (file != null && file!.existsSync()) {
      return Image.file(
        file!,
        width: 74,
        height: 74,
        fit: BoxFit.cover,
      );
    }

    if (imageUrl != null && imageUrl!.startsWith('http')) {
      return Image.network(
        imageUrl!,
        width: 74,
        height: 74,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _Placeholder(isDark: isDark),
      );
    }

    return _Placeholder(isDark: isDark);
  }
}

class _Placeholder extends StatelessWidget {
  final bool isDark;

  const _Placeholder({
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF352548),
                  Color(0xFF4A3570),
                ]
              : const [
                  Color(0xFFFCE7EE),
                  Color(0xFFEDE4FF),
                ],
        ),
      ),
      child: const Icon(
        Icons.image_rounded,
        color: Color(0xFFC09BE5),
        size: 34,
      ),
    );
  }
}