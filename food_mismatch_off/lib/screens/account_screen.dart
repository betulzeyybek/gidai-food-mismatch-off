import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import 'profile_info_screen.dart';
import 'favorites_screen.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  User? user;

  static const Color primaryLilac = Color(0xFF8E73D8);
  static const Color salmon = Color(0xFFF2A39A);
  static const Color mint = Color(0xFF79B89A);

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  Future<void> _showInfoSheet({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sheetColor = isDark
        ? const Color(0xFF2A203A).withValues(alpha: 0.98)
        : Colors.white.withValues(alpha: 0.96);

    final mainText = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF2B2146);
    final subText = isDark ? const Color(0xFFCABBDC) : const Color(0xFF6F6287);
    final itemBg = isDark ? const Color(0xFF362845) : const Color(0xFFF8F3FF);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: primaryLilac.withValues(alpha: isDark ? 0.28 : 0.16),
                blurRadius: 28,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF6E5A88)
                          : const Color(0xFFD8CDED),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(icon, color: color, size: 38),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mainText,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: subText,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ...items.map(
                    (item) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: itemBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryLilac.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: color,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                color: mainText.withValues(alpha: 0.86),
                                fontSize: 14.5,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFD8B7F2),
                            Color(0xFFC09BE5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryLilac.withValues(alpha: 0.24),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Anladım',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmSignOut() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dialogColor = isDark
        ? const Color(0xFF2A203A).withValues(alpha: 0.98)
        : Colors.white.withValues(alpha: 0.96);

    final mainText = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF2B2146);
    final subText = isDark ? const Color(0xFFCABBDC) : const Color(0xFF6F6287);

    final bool? shouldSignOut = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            decoration: BoxDecoration(
              color: dialogColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: salmon.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: salmon.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: salmon,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Çıkış yapmak istiyor musun?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mainText,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Hesabından çıkış yapılacak. Daha sonra tekrar giriş yapabilirsin.',
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
                              color: primaryLilac.withValues(alpha: 0.28),
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
                            backgroundColor: salmon,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Çıkış Yap',
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

    if (shouldSignOut != true) return;

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final fullName = user?.displayName ?? 'Kullanıcı';
    final email = user?.email ?? 'E-posta yok';

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

    final mainText = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF2B2146);
    final subText = isDark ? const Color(0xFFCABBDC) : const Color(0xFF6F6287);
    final cardColor = isDark
        ? const Color(0xFF2A203A).withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.82);

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
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Row(
                  children: [
                    _TopCircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                      isDark: isDark,
                    ),
                    Expanded(
                      child: Text(
                        'Hesabım',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: mainText,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 52),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 26),
                  children: [
                    _ProfileCard(
                      fullName: fullName,
                      email: email,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),
                    _AccountItem(
                      icon: Icons.badge_outlined,
                      title: 'Bilgilerim',
                      subtitle: 'Ad, soyad ve e-posta bilgilerin',
                      color: primaryLilac,
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileInfoScreen(),
                          ),
                        );

                        if (updated == true) {
                          await FirebaseAuth.instance.currentUser?.reload();

                          if (!mounted) return;

                          setState(() {
                            user = FirebaseAuth.instance.currentUser;
                          });
                        }
                      },
                      isDark: isDark,
                      cardColor: cardColor,
                      mainText: mainText,
                      subText: subText,
                    ),
                    _AccountItem(
                      icon: Icons.favorite_border_rounded,
                      title: 'Favoriler',
                      subtitle: 'Kaydettiğin ürünler',
                      color: salmon,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FavoritesScreen(),
                          ),
                        );
                      },
                      isDark: isDark,
                      cardColor: cardColor,
                      mainText: mainText,
                      subText: subText,
                    ),
                    _ThemeSwitchItem(
                      isDarkMode: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme(value);
                      },
                      isDark: isDark,
                      cardColor: cardColor,
                      mainText: mainText,
                      subText: subText,
                    ),
                    _AccountItem(
                      icon: Icons.description_outlined,
                      title: 'Kullanım Koşulları',
                      subtitle: 'Uygulama kullanım kuralları',
                      color: const Color(0xFF9B7BE8),
                      onTap: () {
                        _showInfoSheet(
                          title: 'Kullanım Koşulları',
                          subtitle:
                              'GıdAI uygulamasını kullanırken dikkat edilmesi gereken temel kurallar.',
                          icon: Icons.description_outlined,
                          color: primaryLilac,
                          items: const [
                            'GıdAI, ürün ambalajı ve içerik bilgilerini analiz ederek bilgilendirme sağlar.',
                            'Sonuçlar kesin sağlık tavsiyesi değildir.',
                            'Ürün içerikleri zamanla değişebilir; en güncel bilgi için ürün ambalajı kontrol edilmelidir.',
                            'Alerji, intolerans veya özel sağlık durumu olan kullanıcılar uzman görüşü almalıdır.',
                            'Barkod ve fotoğraf analizleri veri kaynağına ve görsel kalitesine göre farklı sonuçlar verebilir.',
                          ],
                        );
                      },
                      isDark: isDark,
                      cardColor: cardColor,
                      mainText: mainText,
                      subText: subText,
                    ),
                    _AccountItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Veri Politikası',
                      subtitle: 'Verilerinin nasıl işlendiği',
                      color: const Color(0xFFB58BE8),
                      onTap: () {
                        _showInfoSheet(
                          title: 'Veri Politikası',
                          subtitle:
                              'Hesap ve analiz verilerinin uygulama içinde nasıl kullanıldığı.',
                          icon: Icons.privacy_tip_outlined,
                          color: mint,
                          items: const [
                            'Hesap bilgilerin Firebase Authentication ile güvenli şekilde saklanır.',
                            'Analiz kayıtların yalnızca kendi hesabınla ilişkilendirilir.',
                            'Yüklenen ürün fotoğrafları analiz amacıyla kullanılır.',
                            'Uygulama, sonuçları göstermek ve geçmiş analizlerini listelemek için verileri saklayabilir.',
                            'Verilerini silmek istediğinde kayıtlarını uygulama içinden kaldırabilirsin.',
                          ],
                        );
                      },
                      isDark: isDark,
                      cardColor: cardColor,
                      mainText: mainText,
                      subText: subText,
                    ),
                    const SizedBox(height: 14),
                    _LogoutItem(
                      onTap: _confirmSignOut,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _TopCircleButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? const Color(0xFF2A203A).withValues(alpha: 0.86)
        : Colors.white.withValues(alpha: 0.82);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E73D8).withValues(alpha: isDark ? 0.18 : 0.10),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: isDark ? const Color(0xFFF8EDFF) : const Color(0xFF6F61A8),
          size: 28,
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String fullName;
  final String email;
  final bool isDark;

  const _ProfileCard({
    required this.fullName,
    required this.email,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF2B2146);
    final subColor = isDark ? const Color(0xFFCABBDC) : const Color(0xFF6F6287);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF352548),
                  Color(0xFF4A3570),
                  Color(0xFF2A203A),
                ]
              : const [
                  Color(0xFFEDE4FF),
                  Color(0xFFD9C8FF),
                  Color(0xFFFFEEF7),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E73D8).withValues(alpha: isDark ? 0.24 : 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF21172F).withValues(alpha: 0.82)
                  : Colors.white.withValues(alpha: 0.82),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 46,
              color: Color(0xFFB99BE5),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF181226).withValues(alpha: 0.48)
                        : Colors.white.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'gıdAI kullanıcısı ✨',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFD8B7F2) : const Color(0xFF6F61A8),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
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

class _AccountItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;
  final Color cardColor;
  final Color mainText;
  final Color subText;

  const _AccountItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.isDark,
    required this.cardColor,
    required this.mainText,
    required this.subText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.75),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E73D8).withValues(alpha: isDark ? 0.14 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: mainText,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: subText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: color, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeSwitchItem extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;
  final bool isDark;
  final Color cardColor;
  final Color mainText;
  final Color subText;

  const _ThemeSwitchItem({
    required this.isDarkMode,
    required this.onChanged,
    required this.isDark,
    required this.cardColor,
    required this.mainText,
    required this.subText,
  });

  @override
  Widget build(BuildContext context) {
    const primaryLilac = Color(0xFF8E73D8);

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.75),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryLilac.withValues(alpha: isDark ? 0.14 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: primaryLilac.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(19),
              ),
              child: Icon(
                isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: primaryLilac,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Görünüm',
                    style: TextStyle(
                      color: mainText,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDarkMode ? 'Koyu pastel mod aktif' : 'Açık pastel mod aktif',
                    style: TextStyle(
                      color: subText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isDarkMode,
              onChanged: onChanged,
              activeColor: primaryLilac,
              activeTrackColor: const Color(0xFFD8B7F2),
              inactiveThumbColor: const Color(0xFFF2A39A),
              inactiveTrackColor: const Color(0xFFFFDDD7),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutItem extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _LogoutItem({
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const salmon = Color(0xFFF2A39A);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: isDark
            ? salmon.withValues(alpha: 0.12)
            : const Color(0xFFFFEEF3),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: salmon.withValues(alpha: isDark ? 0.24 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: salmon.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.logout_rounded, color: salmon, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Çıkış Yap',
                    style: TextStyle(
                      color: salmon,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: salmon, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}