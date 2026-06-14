import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({super.key});

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isEditing = false;
  bool isLoading = false;
  bool obscurePassword = true;

  String originalEmail = '';

  static const Color primaryLilac = Color(0xFF8E73D8);
  static const Color softLilac = Color(0xFFD7B6FF);
  static const Color salmon = Color(0xFFE9A6A6);

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() {
    final user = FirebaseAuth.instance.currentUser;

    final fullName = user?.displayName ?? '';
    final parts = fullName.trim().split(' ');

    nameController.text =
        parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : '';

    surnameController.text =
        parts.length > 1 ? parts.sublist(1).join(' ') : '';

    emailController.text = user?.email ?? '';
    originalEmail = user?.email ?? '';
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Kullanıcı bulunamadı');
      return;
    }

    final name = nameController.text.trim();
    final surname = surnameController.text.trim();
    final newEmail = emailController.text.trim();
    final currentPassword = passwordController.text.trim();

    if (name.isEmpty || surname.isEmpty || newEmail.isEmpty) {
      _showMessage('Ad, soyad ve e-posta boş olamaz');
      return;
    }

    if (!newEmail.contains('@') || !newEmail.contains('.')) {
      _showMessage('Geçerli bir e-posta adresi gir');
      return;
    }

    final emailChanged = newEmail != originalEmail;

    if (emailChanged && currentPassword.isEmpty) {
      _showMessage('E-postayı değiştirmek için mevcut şifreni girmelisin');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await user.updateDisplayName('$name $surname');

      if (emailChanged) {
        final credential = EmailAuthProvider.credential(
          email: originalEmail,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(credential);
        await user.updateEmail(newEmail);
      }

      await FirebaseAuth.instance.currentUser?.reload();

      if (!mounted) return;

      setState(() {
        isEditing = false;
        isLoading = false;
        originalEmail = newEmail;
        passwordController.clear();
      });

      _showMessage('Bilgiler güncellendi');
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      String message = 'Bilgiler güncellenemedi';

      if (e.code == 'wrong-password') {
        message = 'Mevcut şifre hatalı';
      } else if (e.code == 'invalid-email') {
        message = 'Geçersiz e-posta adresi';
      } else if (e.code == 'email-already-in-use') {
        message = 'Bu e-posta başka bir hesapta kullanılıyor';
      } else if (e.code == 'requires-recent-login') {
        message = 'Güvenlik için tekrar giriş yapman gerekiyor';
      } else if (e.code == 'network-request-failed') {
        message = 'İnternet bağlantını kontrol et';
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(message);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage('Beklenmeyen hata: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emailChanged = emailController.text.trim() != originalEmail;

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
    final softText = isDark ? const Color(0xFFCABBDC) : const Color(0xFF6F6287);

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
                    _TopButton(
                      icon: Icons.arrow_back_rounded,
                      isDark: isDark,
                      onTap: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Bilgilerim',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: mainText,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    _TopButton(
                      icon: isEditing ? Icons.close_rounded : Icons.edit_rounded,
                      isDark: isDark,
                      onTap: () {
                        setState(() {
                          if (isEditing) {
                            _loadUserInfo();
                            passwordController.clear();
                          }

                          isEditing = !isEditing;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 26),
                  children: [
                    _InfoHeaderCard(
                      isEditing: isEditing,
                      isDark: isDark,
                      mainText: mainText,
                      softText: softText,
                    ),
                    const SizedBox(height: 22),
                    _ProfileField(
                      controller: nameController,
                      label: 'Ad',
                      icon: Icons.person_outline_rounded,
                      enabled: isEditing,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _ProfileField(
                      controller: surnameController,
                      label: 'Soyad',
                      icon: Icons.badge_outlined,
                      enabled: isEditing,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _ProfileField(
                      controller: emailController,
                      label: 'E-posta',
                      icon: Icons.mail_outline_rounded,
                      enabled: isEditing,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() {}),
                      isDark: isDark,
                    ),
                    if (isEditing && emailChanged) ...[
                      const SizedBox(height: 14),
                      _PasswordField(
                        controller: passwordController,
                        obscurePassword: obscurePassword,
                        isDark: isDark,
                        onToggle: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'E-posta değişikliği için mevcut şifren gerekir.',
                        style: TextStyle(
                          color: softText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),
                    if (isEditing)
                      GestureDetector(
                        onTap: isLoading ? null : _saveChanges,
                        child: Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(23),
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
                                color: primaryLilac.withValues(alpha: 0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: isLoading
                                ? const SizedBox(
                                    width: 25,
                                    height: 25,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Text(
                                    'Kaydet',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                          ),
                        ),
                      )
                    else
                      _InfoNoteCard(
                        isDark: isDark,
                        mainText: mainText,
                        softText: softText,
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
        : Colors.white.withValues(alpha: 0.82);

    final iconColor = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF6F61A8);

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
                : const Color(0xFF8E73D8).withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 7),
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

class _InfoHeaderCard extends StatelessWidget {
  final bool isEditing;
  final bool isDark;
  final Color mainText;
  final Color softText;

  const _InfoHeaderCard({
    required this.isEditing,
    required this.isDark,
    required this.mainText,
    required this.softText,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = isDark
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.28)
                : const Color(0xFF8E73D8).withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF8E73D8),
              size: 38,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              isEditing
                  ? 'Bilgilerini düzenliyorsun'
                  : 'Kayıtlı profil bilgilerin',
              style: TextStyle(
                color: mainText,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final bool isDark;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.isDark,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const primaryLilac = Color(0xFF8E73D8);
    const salmon = Color(0xFFE9A6A6);

    final mainText = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF2B2146);
    final labelText = isDark ? const Color(0xFFCABBDC) : const Color(0xFF6F6287);

    final fieldColor = isDark
        ? const Color(0xFF2A203A).withValues(alpha: enabled ? 0.92 : 0.68)
        : Colors.white.withValues(alpha: enabled ? 0.9 : 0.62);

    return Container(
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: enabled
              ? primaryLilac.withValues(alpha: isDark ? 0.42 : 0.32)
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.75),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.20)
                : primaryLilac.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: TextStyle(
          color: mainText,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 22,
          ),
          prefixIcon: Icon(
            icon,
            color: enabled ? primaryLilac : salmon,
            size: 28,
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: labelText,
            fontWeight: FontWeight.w700,
          ),
          disabledBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscurePassword;
  final VoidCallback onToggle;
  final bool isDark;

  const _PasswordField({
    required this.controller,
    required this.obscurePassword,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const primaryLilac = Color(0xFF8E73D8);

    final mainText = isDark ? const Color(0xFFF8EDFF) : const Color(0xFF2B2146);
    final labelText = isDark ? const Color(0xFFCABBDC) : const Color(0xFF6F6287);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A203A).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primaryLilac.withValues(alpha: isDark ? 0.42 : 0.32),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.20)
                : primaryLilac.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscurePassword,
        style: TextStyle(
          color: mainText,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 22,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: primaryLilac,
            size: 28,
          ),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: primaryLilac,
            ),
          ),
          labelText: 'Mevcut şifre',
          labelStyle: TextStyle(
            color: labelText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InfoNoteCard extends StatelessWidget {
  final bool isDark;
  final Color mainText;
  final Color softText;

  const _InfoNoteCard({
    required this.isDark,
    required this.mainText,
    required this.softText,
  });

  @override
  Widget build(BuildContext context) {
    const primaryLilac = Color(0xFF8E73D8);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A203A).withValues(alpha: 0.82)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : primaryLilac.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: primaryLilac,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bilgilerini değiştirmek için sağ üstteki edit butonuna basınız.',
              style: TextStyle(
                color: softText,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}