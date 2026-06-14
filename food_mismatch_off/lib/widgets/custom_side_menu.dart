import 'package:flutter/material.dart';

class CustomSideMenu extends StatelessWidget {
  final String userName;
  final VoidCallback onHome;
  final VoidCallback onSearch;
  final VoidCallback onSaved;
  final VoidCallback onFavorites;
  final VoidCallback onAdditives;
  final VoidCallback onAccount;
  final VoidCallback onLogout;

  const CustomSideMenu({
    super.key,
    required this.userName,
    required this.onHome,
    required this.onSearch,
    required this.onSaved,
    required this.onFavorites,
    required this.onAdditives,
    required this.onAccount,
    required this.onLogout,
  });

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

    final cardColor = isDark
        ? const Color(0xFF2A203A).withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.72);

    final mainText = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF2B2146);
    final subText = isDark ? const Color(0xFFCABBDC) : const Color(0xFF8A7A9A);

    return Drawer(
      width: 300,
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 18, 0, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          gradient: LinearGradient(
            colors: bgColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.34)
                  : const Color(0xFF8E73D8).withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.75),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.22)
                            : const Color(0xFF8E73D8).withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFD7B6FF),
                              Color(0xFF8E73D8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF8E73D8).withValues(alpha: 0.26),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.document_scanner_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'gıdAI',
                              style: TextStyle(
                                fontSize: 28,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                color: mainText,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ambalaj analiz asistanın',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                                color: subText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A203A).withValues(alpha: 0.72)
                          : Colors.white.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      'Merhaba, $userName',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFD8B7F2)
                            : const Color(0xFF6F61A8),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                _MenuItem(
                  icon: Icons.home_rounded,
                  title: 'Ana Sayfa',
                  selected: true,
                  isDark: isDark,
                  onTap: onHome,
                ),
                _MenuItem(
                  icon: Icons.document_scanner_rounded,
                  title: 'Ürün Ara',
                  isDark: isDark,
                  onTap: onSearch,
                ),
                _MenuItem(
                  icon: Icons.folder_open_rounded,
                  title: 'Kayıtlarım',
                  isDark: isDark,
                  onTap: onSaved,
                ),
                _MenuItem(
                  icon: Icons.favorite_border_rounded,
                  title: 'Favoriler',
                  isDark: isDark,
                  onTap: onFavorites,
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Divider(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE0D6F5),
                    thickness: 1,
                  ),
                ),

                _MenuItem(
                  icon: Icons.menu_book_rounded,
                  title: 'Katkı Rehberi',
                  isDark: isDark,
                  onTap: onAdditives,
                ),
                _MenuItem(
                  icon: Icons.person_rounded,
                  title: 'Hesabım',
                  isDark: isDark,
                  onTap: onAccount,
                ),

                const SizedBox(height: 8),

                _MenuItem(
                  icon: Icons.logout_rounded,
                  title: 'Çıkış Yap',
                  isDark: isDark,
                  onTap: onLogout,
                ),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A203A).withValues(alpha: 0.72)
                        : Colors.white.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: isDark
                            ? const Color(0xFFD8B7F2)
                            : const Color(0xFF8E73D8),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pastel görünüm modu aktif',
                          style: TextStyle(
                            color: subText,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
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

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    const primaryLilac = Color(0xFF8E73D8);

    final mainText = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF2B2146);
    final inactiveIcon =
        isDark ? const Color(0xFFCABBDC) : const Color(0xFF7F748D);

    final iconColor = selected ? primaryLilac : inactiveIcon;
    final textColor = selected ? primaryLilac : mainText;

    final itemColor = selected
        ? isDark
            ? const Color(0xFF342747).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.76)
        : isDark
            ? const Color(0xFF2A203A).withValues(alpha: 0.58)
            : Colors.white.withValues(alpha: 0.36);

    final iconBg = selected
        ? isDark
            ? const Color(0xFF3E2E58)
            : const Color(0xFFF1EAFF)
        : isDark
            ? const Color(0xFF21172F).withValues(alpha: 0.70)
            : Colors.white.withValues(alpha: 0.62);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: itemColor,
        borderRadius: BorderRadius.circular(23),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(23),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              border: Border.all(
                color: selected
                    ? primaryLilac.withValues(alpha: isDark ? 0.28 : 0.16)
                    : isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: primaryLilac,
                      shape: BoxShape.circle,
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