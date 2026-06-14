import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kAdditiveLilac = Color(0xFFB99BE5);
const Color kAdditiveDarkLilac = Color(0xFF8E73D8);
const Color kAdditiveSalmon = Color(0xFFF2A39A);
const Color kAdditiveMint = Color(0xFF79B89A);
const Color kAdditiveOrange = Color(0xFFF1A51E);
const Color kAdditiveRed = Color(0xFFE67C8E);

class AdditiveGuideScreen extends StatefulWidget {
  const AdditiveGuideScreen({super.key});

  @override
  State<AdditiveGuideScreen> createState() => _AdditiveGuideScreenState();
}

class _AdditiveGuideScreenState extends State<AdditiveGuideScreen> {
  final TextEditingController searchController = TextEditingController();

  final List<Map<String, String>> additives = const [
    {
      'code': 'E102',
      'name': 'Tartrazin',
      'category': 'Renklendirici',
      'risk': 'Orta',
      'usage': 'Gıdalara sarı renk vermek için kullanılır.',
    },
    {
      'code': 'E110',
      'name': 'Sunset Yellow',
      'category': 'Renklendirici',
      'risk': 'Orta',
      'usage': 'Turuncu-sarı renk vermek için kullanılır.',
    },
    {
      'code': 'E124',
      'name': 'Ponceau 4R',
      'category': 'Renklendirici',
      'risk': 'Orta',
      'usage': 'Kırmızı renk vermek için kullanılır.',
    },
    {
      'code': 'E211',
      'name': 'Sodyum Benzoat',
      'category': 'Koruyucu',
      'risk': 'Orta',
      'usage': 'Mikroorganizmaların gelişimini engellemek için kullanılır.',
    },
    {
      'code': 'E250',
      'name': 'Sodyum Nitrit',
      'category': 'Koruyucu',
      'risk': 'Yüksek',
      'usage': 'Et ürünlerinde renk koruma ve mikrobiyal kontrol için kullanılır.',
    },
    {
      'code': 'E621',
      'name': 'Monosodyum Glutamat',
      'category': 'Tatlandırıcı / Aroma Verici',
      'risk': 'Orta',
      'usage': 'Umami tat vermek ve lezzet artırmak için kullanılır.',
    },
  ];

  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get filteredAdditives {
    final q = query.toLowerCase().trim();

    if (q.isEmpty) return additives;

    return additives.where((item) {
      return item['code']!.toLowerCase().contains(q) ||
          item['name']!.toLowerCase().contains(q) ||
          item['category']!.toLowerCase().contains(q) ||
          item['risk']!.toLowerCase().contains(q);
    }).toList();
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
            Color(0xFFFFF8F3),
            Color(0xFFFDF5FA),
            Color(0xFFEFE7FA),
          ];

    final mainText = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF3B2B5C);
    final softText = isDark ? const Color(0xFFCABBDC) : const Color(0xFF8D7A86);

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
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
            children: [
              _TopBar(
                title: 'Katkı Maddeleri',
                isDark: isDark,
                mainText: mainText,
              ),
              const SizedBox(height: 24),

              _HeroCard(
                isDark: isDark,
                mainText: mainText,
                softText: softText,
              ),

              const SizedBox(height: 20),

              _SearchBox(
                controller: searchController,
                isDark: isDark,
                mainText: mainText,
                softText: softText,
                onChanged: (value) {
                  setState(() {
                    query = value;
                  });
                },
              ),

              const SizedBox(height: 28),

              _SectionTitle(
                title: 'Risk Seviyeleri',
                color: mainText,
              ),

              const SizedBox(height: 14),

              SizedBox(
                height: 205,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _RiskBox(
                      title: 'Düşük',
                      text: 'Genel olarak düşük dikkat gerektirir.',
                      icon: Icons.eco_rounded,
                      color: kAdditiveMint,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    _RiskBox(
                      title: 'Orta',
                      text: 'Hassas bireylerde dikkat gerektirebilir.',
                      icon: Icons.priority_high_rounded,
                      color: kAdditiveOrange,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 12),
                    _RiskBox(
                      title: 'Yüksek',
                      text: 'Dikkatli tüketilmesi önerilir.',
                      icon: Icons.shield_outlined,
                      color: kAdditiveRed,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              _SectionTitle(
                title: 'Sık Karşılaşılan Katkılar',
                color: mainText,
              ),

              const SizedBox(height: 14),

              if (filteredAdditives.isEmpty)
                _EmptyResultCard(
                  isDark: isDark,
                  softText: softText,
                )
              else
                ...filteredAdditives.map(
                  (item) => _AdditiveCard(
                    code: item['code']!,
                    name: item['name']!,
                    category: item['category']!,
                    risk: item['risk']!,
                    usage: item['usage']!,
                    isDark: isDark,
                    mainText: mainText,
                    softText: softText,
                  ),
                ),

              const SizedBox(height: 12),

              _ReminderCard(
                isDark: isDark,
                mainText: mainText,
                softText: softText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final bool isDark;
  final Color mainText;

  const _TopBar({
    required this.title,
    required this.isDark,
    required this.mainText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A203A).withValues(alpha: 0.88)
                  : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.24)
                      : kAdditiveLilac.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: mainText,
              size: 29,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.nunito(
              color: mainText,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final bool isDark;
  final Color mainText;
  final Color softText;

  const _HeroCard({
    required this.isDark,
    required this.mainText,
    required this.softText,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? const Color(0xFF2A203A).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.78);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.85),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.26)
                : kAdditiveLilac.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF3A2A4E).withValues(alpha: 0.82)
                  : const Color(0xFFFFECE8).withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.science_outlined,
                  size: 52,
                  color: kAdditiveLilac,
                ),
                Positioned(
                  top: 22,
                  right: 23,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: kAdditiveSalmon.withValues(alpha: 0.75),
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'E-kodları nasıl\nyorumlamalıyım?',
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? const Color(0xFFF2A39A)
                        : const Color(0xFFC55B72),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Katkı maddelerini risk seviyesine göre inceleyebilir ve ürün içeriklerini daha bilinçli yorumlayabilirsin.',
                  style: GoogleFonts.nunito(
                    color: softText,
                    fontSize: 14.5,
                    height: 1.35,
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

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final Color mainText;
  final Color softText;
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.controller,
    required this.isDark,
    required this.mainText,
    required this.softText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A203A).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: kAdditiveLilac.withValues(alpha: isDark ? 0.26 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.22)
                : kAdditiveLilac.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.nunito(
          color: mainText,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          hintText: 'E-kod veya katkı maddesi ara...',
          hintStyle: GoogleFonts.nunito(
            color: softText.withValues(alpha: 0.75),
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: kAdditiveLilac,
            size: 30,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionTitle({
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _RiskBox extends StatelessWidget {
  final String title;
  final String text;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _RiskBox({
    required this.title,
    required this.text,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final boxText = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF3B2B5C);

    return Container(
      width: 180,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.13),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.34 : 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.22)
                : color.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.nunito(
              color: boxText.withValues(alpha: 0.90),
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdditiveCard extends StatelessWidget {
  final String code;
  final String name;
  final String category;
  final String risk;
  final String usage;
  final bool isDark;
  final Color mainText;
  final Color softText;

  const _AdditiveCard({
    required this.code,
    required this.name,
    required this.category,
    required this.risk,
    required this.usage,
    required this.isDark,
    required this.mainText,
    required this.softText,
  });

  Color get riskColor {
    switch (risk.toLowerCase()) {
      case 'düşük':
        return kAdditiveMint;
      case 'orta':
        return kAdditiveOrange;
      case 'yüksek':
        return kAdditiveRed;
      default:
        return kAdditiveLilac;
    }
  }

  IconData get additiveIcon {
    if (category.toLowerCase().contains('koruyucu')) {
      return Icons.shield_outlined;
    }

    if (category.toLowerCase().contains('tatlandırıcı') ||
        category.toLowerCase().contains('aroma')) {
      return Icons.restaurant_rounded;
    }

    return Icons.color_lens_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A203A).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.82),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.24)
                : kAdditiveLilac.withValues(alpha: 0.09),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: isDark ? 0.18 : 0.14),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Center(
              child: Text(
                code,
                style: GoogleFonts.nunito(
                  color: riskColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
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
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: mainText,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniBadge(text: category, color: kAdditiveLilac),
                    _MiniBadge(text: risk, color: riskColor),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  usage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    color: softText,
                    fontSize: 13.5,
                    height: 1.28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: isDark ? 0.16 : 0.11),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              additiveIcon,
              color: riskColor,
              size: 25,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 135),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.nunito(
          color: color,
          fontSize: 12.2,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyResultCard extends StatelessWidget {
  final bool isDark;
  final Color softText;

  const _EmptyResultCard({
    required this.isDark,
    required this.softText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A203A).withValues(alpha: 0.90)
            : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Text(
        'Aramana uygun katkı maddesi bulunamadı.',
        textAlign: TextAlign.center,
        style: GoogleFonts.nunito(
          color: softText,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final bool isDark;
  final Color mainText;
  final Color softText;

  const _ReminderCard({
    required this.isDark,
    required this.mainText,
    required this.softText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF56323D).withValues(alpha: 0.55)
            : const Color(0xFFFFECE8).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: kAdditiveSalmon.withValues(alpha: isDark ? 0.28 : 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF181226).withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: kAdditiveSalmon,
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Bu bilgiler tanı veya tedavi önerisi değildir. Hassasiyet, alerji veya özel sağlık durumlarında uzman görüşü alınmalıdır.',
              style: GoogleFonts.nunito(
                color: mainText.withValues(alpha: 0.90),
                height: 1.35,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}