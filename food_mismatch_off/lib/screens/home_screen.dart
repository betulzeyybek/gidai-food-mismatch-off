import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/custom_side_menu.dart';
import 'favorites_screen.dart';
import 'account_screen.dart';
import 'additive_guide_screen.dart';
import 'visual_analysis_upload_screen.dart';
import 'saved_images_screen.dart';
import 'barcode_search_screen.dart';
import 'result_screen.dart';
import 'analysis_guide_screen.dart';
import 'about_screen.dart';
import '../services/saved_images_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _recentFuture;

  @override
  void initState() {
    super.initState();
    _recentFuture = SavedImagesService.getSavedItems();
  }

  void _refreshRecent() {
    setState(() {
      _recentFuture = SavedImagesService.getSavedItems();
    });
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final savedPath = await SavedImagesService.saveToAppFolder(image.path);

      if (!context.mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(imagePath: savedPath),
        ),
      );

      _refreshRecent();
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Galeri hatası: $e')),
      );
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  void _showProductSearchOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sheetColors = isDark
        ? const [
            Color(0xFF181226),
            Color(0xFF241A36),
            Color(0xFF2E2144),
          ]
        : const [
            Color(0xFFFFF7FA),
            Color(0xFFF2ECFF),
            Color(0xFFEAF6EA),
          ];

    final mainText = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF1B223B);
    final subText = isDark ? const Color(0xFFCABBDC) : const Color(0xFF666C7A);
    final optionCardColor = isDark
        ? const Color(0xFF2A203A).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.75);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 34),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: sheetColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(34),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF6E5A88)
                        : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Nasıl analiz etmek istersin?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: mainText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Barkod girerek veya ürün fotoğrafı yükleyerek analiz başlat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: subText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                _BottomOptionCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Barkodla Ara',
                  subtitle: 'Ürünün barkod numarasını gir',
                  color: optionCardColor,
                  iconColor: const Color(0xFFB99BE5),
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BarcodeSearchScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _BottomOptionCard(
                  icon: Icons.camera_alt_rounded,
                  title: 'Görseli Tara',
                  subtitle: 'Ön yüz ve içindekiler kısmını yükle',
                  color: optionCardColor,
                  iconColor: const Color(0xFFF2A39A),
                  isDark: isDark,
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VisualAnalysisUploadScreen(),
                      ),
                    );
                    _refreshRecent();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryLilac = const Color(0xFF8E73D8);
    final darkLilac = isDark ? const Color(0xFFD8B7F2) : const Color(0xFF6F61A8);

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

    final mainText = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF1B223B);
    final subText = isDark ? const Color(0xFFCABBDC) : const Color(0xFF666C7A);
    final emptyCardColor = isDark
        ? const Color(0xFF2A203A).withValues(alpha: 0.88)
        : Colors.white;

    return Scaffold(
      backgroundColor: bgColors.first,
      drawer: CustomSideMenu(
        userName: user?.displayName?.split(' ').first ?? 'Kullanıcı',
        onHome: () => Navigator.pop(context),
        onSearch: () {
          Navigator.pop(context);
          _showProductSearchOptions(context);
        },
        onSaved: () async {
          Navigator.pop(context);
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SavedImagesScreen()),
          );
          _refreshRecent();
        },
        onFavorites: () async {
          Navigator.pop(context);
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
          );
          _refreshRecent();
        },
        onAdditives: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdditiveGuideScreen()),
          );
        },
        onAccount: () async {
          Navigator.pop(context);
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AccountScreen()),
          );
          await FirebaseAuth.instance.currentUser?.reload();

          if (!mounted) return;

          setState(() {});
        },
        onLogout: () => _signOut(context),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(
                          builder: (context) {
                            return _TopIconButton(
                              icon: Icons.menu_rounded,
                              color: darkLilac,
                              isDark: isDark,
                              onTap: () {
                                Scaffold.of(context).openDrawer();
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Merhaba, ${user?.displayName?.split(' ').first ?? "Kullanıcı"}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: mainText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bugün ne analiz etmek istersin?',
                      style: TextStyle(
                        fontSize: 14,
                        color: subText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 22),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _recentFuture,
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;

                        return _PastelHeroCard(
                          analysisCount: count,
                          isDark: isDark,
                          onTap: () => _showProductSearchOptions(context),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Son Analizler',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: mainText,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SavedImagesScreen(),
                              ),
                            );
                            _refreshRecent();
                          },
                          child: Text(
                            'Tümünü Gör',
                            style: TextStyle(
                              color: darkLilac,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _recentFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: primaryLilac,
                              ),
                            ),
                          );
                        }

                        final items = snapshot.data ?? [];

                        if (items.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: emptyCardColor,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.white.withValues(alpha: 0.65),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.20 : 0.04,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Text(
                              'Henüz analiz yok. Ürün Ara butonuyla ilk analizini başlatabilirsin.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: subText,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                          );
                        }

                        final recentItems = items.take(2).toList();

                        return Column(
                          children: recentItems.map((item) {
                            final imagePath = item['frontImagePath'] ?? item['path'];
                            final risk = item['healthRisk'] ?? 'Bilinmiyor';
                            final score = item['misleadingScore'];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _RecentAnalysisCard(
                                title: item['productName'] ?? 'Analiz Edilen Ürün',
                                date: 'Analiz tarihi: ${_formatDate(item['createdAt'])}',
                                score: score != null
                                    ? 'Yanıltıcılık skoru: $score'
                                    : 'Skor hazırlanıyor',
                                chipText: risk.toString().toUpperCase(),
                                chipColor: _riskBgColor(
                                  risk.toString(),
                                  isDark: isDark,
                                ),
                                imagePath: imagePath,
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
                                  _refreshRecent();
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              _BottomHomeBar(
                isDark: isDark,
                onHomeTap: () => _refreshRecent(),
                onCenterTap: () => _showProductSearchOptions(context),
                onSavedTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SavedImagesScreen()),
                  );
                  _refreshRecent();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return 'Bilinmiyor';

    final date = DateTime.tryParse(iso);

    if (date == null) return 'Bilinmiyor';

    return '${date.day}.${date.month}.${date.year}';
  }

  Color _riskBgColor(String risk, {required bool isDark}) {
    switch (risk.toLowerCase()) {
      case 'düşük':
        return isDark ? const Color(0xFF315A49) : const Color(0xFFDDF0DD);
      case 'orta':
        return isDark ? const Color(0xFF6A4E2C) : const Color(0xFFF3D8B2);
      case 'yüksek':
        return isDark ? const Color(0xFF6A333A) : const Color(0xFFF5C4C4);
      default:
        return isDark ? const Color(0xFF3A3149) : const Color(0xFFECECEC);
    }
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _TopIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A203A).withValues(alpha: 0.88)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: color),
      ),
    );
  }
}

class _RecentAnalysisCard extends StatelessWidget {
  final String title;
  final String date;
  final String score;
  final String chipText;
  final Color chipColor;
  final String? imagePath;
  final VoidCallback onTap;
  final bool isDark;

  const _RecentAnalysisCard({
    required this.title,
    required this.date,
    required this.score,
    required this.chipText,
    required this.chipColor,
    required this.imagePath,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final file = imagePath != null ? File(imagePath!) : null;

    final cardColor = isDark
        ? const Color(0xFF2A203A).withValues(alpha: 0.90)
        : Colors.white;

    final mainText = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF1B223B);
    final subText = isDark ? const Color(0xFFCABBDC) : Colors.grey.shade700;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.65),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: file != null && file.existsSync()
                  ? Image.file(
                      file,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      color: isDark
                          ? const Color(0xFF3A2A4E)
                          : const Color(0xFFFCE7EE),
                      child: const Icon(
                        Icons.local_drink_rounded,
                        size: 36,
                        color: Color(0xFFF2A39A),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: mainText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: TextStyle(
                      color: subText,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          score,
                          style: TextStyle(
                            color: subText,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: chipColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          chipText,
                          style: TextStyle(
                            color: isDark ? const Color(0xFFF8EDFF) : Colors.black87,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomHomeBar extends StatelessWidget {
  final VoidCallback onHomeTap;
  final VoidCallback onCenterTap;
  final VoidCallback onSavedTap;
  final bool isDark;

  const _BottomHomeBar({
    required this.onHomeTap,
    required this.onCenterTap,
    required this.onSavedTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const primaryLilac = Color(0xFF8E73D8);
    const softLilac = Color(0xFFD8C8FF);

    final bgColor = isDark
        ? const Color(0xFF21172F).withValues(alpha: 0.96)
        : Colors.white;

    final inactiveColor = isDark ? const Color(0xFFCABBDC) : Colors.grey;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onHomeTap,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.home_rounded,
                    color: primaryLilac,
                    size: 28,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ana Sayfa',
                    style: TextStyle(
                      color: primaryLilac,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: onCenterTap,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    softLilac,
                    primaryLilac,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryLilac.withValues(alpha: isDark ? 0.36 : 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onSavedTap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    color: inactiveColor,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kayıtlarım',
                    style: TextStyle(
                      color: inactiveColor,
                      fontWeight: FontWeight.w700,
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

class _BottomOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isDark;

  const _BottomOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconColor,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final mainText = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF1B223B);
    final subText = isDark ? const Color(0xFFCABBDC) : Colors.grey.shade700;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF181226).withValues(alpha: 0.70)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: mainText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: subText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PastelHeroCard extends StatelessWidget {
  final VoidCallback onTap;
  final int analysisCount;
  final bool isDark;

  const _PastelHeroCard({
    required this.onTap,
    required this.analysisCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final mainText = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF1B223B);
    final subText = isDark ? const Color(0xFFCABBDC) : const Color(0xFF555A6F);

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF2A203A),
                  Color(0xFF3A2A4E),
                  Color(0xFF241A36),
                ]
              : const [
                  Color(0xFFEAF6EA),
                  Color(0xFFF2ECFF),
                  Color(0xFFFFEEF4),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.28)
                : const Color(0xFFB7A9E6).withValues(alpha: 0.55),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            bottom: -12,
            child: Opacity(
              opacity: isDark ? 0.55 : 0.75,
              child: Image.asset(
                'assets/images/product2.png',
                width: 175,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF181226).withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'GıdAI ✨',
                style: TextStyle(
                  color: isDark ? const Color(0xFFD8B7F2) : const Color(0xFF6F61A8),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF181226).withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                '$analysisCount\nanaliz',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? const Color(0xFFD8B7F2) : const Color(0xFF6F61A8),
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ),
          ),
          Positioned(
            left: 22,
            top: 76,
            child: Text(
              'Ürünün gerçek\nhikayesini keşfet',
              style: TextStyle(
                color: mainText,
                fontSize: 28,
                height: 1.12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned(
            left: 22,
            top: 156,
            child: Text(
              'İçeriğini analiz et, sağlık risklerini öğren.',
              style: TextStyle(
                color: subText,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            left: 22,
            bottom: 22,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 230,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF181226).withValues(alpha: 0.72)
                      : Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.document_scanner_rounded,
                      color: Color(0xFFB99BE5),
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ürün Ara',
                            style: TextStyle(
                              color: mainText,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Barkod veya fotoğraf ile tara',
                            style: TextStyle(
                              color: subText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFB99BE5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}