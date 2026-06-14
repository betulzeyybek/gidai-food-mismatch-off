import 'login_screen.dart';
import 'home_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  final Color darkText = const Color(0xFF594653);
  final Color softText = const Color(0xFF8D7A86);
  final Color lilac = const Color(0xFFB99BE5);
 final Color pink = const Color(0xFFF2A39A);
  final Color mint = const Color(0xFF79B89A);

  Future<void> register() async {
    final name = nameController.text.trim();
    final surname = surnameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty ||
        surname.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun")),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şifre en az 6 karakter olmalıdır")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şifreler eşleşmiyor")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName("$name $surname");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıt başarılı")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = "Kayıt başarısız";

      if (e.code == 'email-already-in-use') {
        message = "Bu e-posta zaten kullanımda";
      } else if (e.code == 'invalid-email') {
        message = "Geçersiz e-posta adresi";
      } else if (e.code == 'weak-password') {
        message = "Şifre çok zayıf";
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Beklenmeyen hata: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showComingSoon(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$provider ile kayıt yakında aktif olacak")),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/auth_pastel_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
                child: Column(
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 10),
                    _buildHeader(),
                    const SizedBox(height: 18),
                    _buildRegisterCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: darkText,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        _buildScanLogo(),
        const SizedBox(height: 16),
        Text(
          "GıdAI",
          style: GoogleFonts.nunito(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: darkText,
            height: 1,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "İçeriğini keşfet, sana uygun ürünleri bul.",
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 15.5,
            height: 1.35,
            fontWeight: FontWeight.w700,
            color: softText,
          ),
        ),
      ],
    );
  }

  Widget _buildScanLogo() {
    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEFE7FA).withValues(alpha: 0.72),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBFA7E8).withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFBFA7E8).withValues(alpha: 0.13),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 39,
                height: 46,
                decoration: BoxDecoration(
                  color: lilac,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _whiteLine(20),
                    const SizedBox(height: 5),
                    _whiteLine(16),
                    const SizedBox(height: 5),
                    _whiteLine(20),
                  ],
                ),
              ),
              Positioned(
                top: 20,
                left: 20,
                child: _scanCorner(topLeft: true),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: _scanCorner(topRight: true),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                child: _scanCorner(bottomLeft: true),
              ),
              Positioned(
                bottom: 20,
                right: 20,
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
      height: 4,
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
      radius = const BorderRadius.only(topLeft: Radius.circular(5));
    } else if (topRight) {
      radius = const BorderRadius.only(topRight: Radius.circular(5));
    } else if (bottomLeft) {
      radius = const BorderRadius.only(bottomLeft: Radius.circular(5));
    } else if (bottomRight) {
      radius = const BorderRadius.only(bottomRight: Radius.circular(5));
    }

    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        border: Border(
          top: topLeft || topRight
              ? BorderSide(color: lilac, width: 3.2)
              : BorderSide.none,
          bottom: bottomLeft || bottomRight
              ? BorderSide(color: lilac, width: 3.2)
              : BorderSide.none,
          left: topLeft || bottomLeft
              ? BorderSide(color: lilac, width: 3.2)
              : BorderSide.none,
          right: topRight || bottomRight
              ? BorderSide(color: lilac, width: 3.2)
              : BorderSide.none,
        ),
        borderRadius: radius,
      ),
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.92),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBFAEDB).withValues(alpha: 0.24),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Kayıt Ol",
            style: GoogleFonts.nunito(
              fontSize: 31,
              fontWeight: FontWeight.w900,
              color: darkText,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Yeni hesabını oluştur ve analize başla.",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: softText,
            ),
          ),
          const SizedBox(height: 22),

          _buildInput(
            controller: nameController,
            hint: "Ad",
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 14),

          _buildInput(
            controller: surnameController,
            hint: "Soyad",
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 14),

          _buildInput(
            controller: emailController,
            hint: "E-posta",
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),

          _buildInput(
            controller: passwordController,
            hint: "Şifre",
            icon: Icons.lock_outline_rounded,
            isPassword: true,
          ),
          const SizedBox(height: 14),

          _buildInput(
            controller: confirmPasswordController,
            hint: "Şifre Tekrar",
            icon: Icons.lock_outline_rounded,
            isConfirmPassword: true,
          ),

          const SizedBox(height: 18),

          SizedBox(
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
                    color: lilac.withValues(alpha: 0.35),
                    blurRadius: 22,
                    offset: const Offset(0, 11),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : register,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 27,
                        height: 27,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        "Kayıt Ol",
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: Divider(
                  color: const Color(0xFFD9CDD9).withValues(alpha: 0.9),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Text(
                  "veya",
                  style: GoogleFonts.nunito(
                    color: softText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: const Color(0xFFD9CDD9).withValues(alpha: 0.9),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _socialButton(
                  label: "Google",
                  icon: Icons.g_mobiledata_rounded,
                  onTap: () => showComingSoon("Google"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _socialButton(
                  label: "Apple",
                  icon: Icons.apple_rounded,
                  onTap: () => showComingSoon("Apple"),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: const Color(0xFF7A6670),
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  const TextSpan(text: "Zaten hesabın var mı? "),
                  TextSpan(
                    text: "Giriş yap",
                    style: TextStyle(
                      color: pink,
                      fontWeight: FontWeight.w900,
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

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isConfirmPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE7D9E5).withValues(alpha: 0.95),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: lilac.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword
            ? obscurePassword
            : isConfirmPassword
                ? obscureConfirmPassword
                : false,
        style: GoogleFonts.nunito(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: darkText,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 17),
          prefixIcon: Icon(
            icon,
            color: isPassword || isConfirmPassword ? pink : lilac,
            size: 25,
          ),
          hintText: hint,
          hintStyle: GoogleFonts.nunito(
            color: const Color(0xFFBDAFB9),
            fontWeight: FontWeight.w800,
          ),
          suffixIcon: isPassword || isConfirmPassword
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      if (isPassword) {
                        obscurePassword = !obscurePassword;
                      } else {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      }
                    });
                  },
                  icon: Icon(
                    (isPassword && obscurePassword) ||
                            (isConfirmPassword && obscureConfirmPassword)
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: lilac,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _socialButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: const Color(0xFFE4D7E2).withValues(alpha: 0.95),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 13,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: icon == Icons.apple_rounded
                  ? const Color(0xFF3C3338)
                  : const Color(0xFFD95C76),
              size: icon == Icons.g_mobiledata_rounded ? 32 : 25,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}