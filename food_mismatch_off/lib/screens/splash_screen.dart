import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _scanController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scaleAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    );

    _scanAnimation = Tween<double>(begin: -35, end: 35).animate(
      CurvedAnimation(
        parent: _scanController,
        curve: Curves.easeInOut,
      ),
    );

    _logoController.forward();

    Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) {
            if (user == null) {
              return const LoginScreen();
            } else {
              return const HomeScreen();
            }
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF9FB),
              Color(0xFFF2ECFF),
              Color(0xFFEFFAF3),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 120,
              right: 40,
              child: _softCircle(const Color(0xFFE7D9FF), 120),
            ),
            Positioned(
              bottom: 90,
              left: -20,
              child: _softCircle(const Color(0xFFDFF7EA), 160),
            ),
            Positioned(
              bottom: 230,
              right: -30,
              child: _softCircle(const Color(0xFFFFF1D8), 140),
            ),

            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 185,
                            height: 185,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.72),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8E73D8)
                                      .withOpacity(0.18),
                                  blurRadius: 45,
                                  offset: const Offset(0, 22),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            width: 118,
                            height: 118,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(36),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7E6ADB)
                                      .withOpacity(0.18),
                                  blurRadius: 30,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.document_scanner_rounded,
                              size: 62,
                              color: Color(0xFF8E73D8),
                            ),
                          ),

                          AnimatedBuilder(
                            animation: _scanAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _scanAnimation.value),
                                child: Container(
                                  width: 115,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Color(0xFF6FD39C),
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6FD39C)
                                            .withOpacity(0.8),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 34),

                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'gıd',
                              style: TextStyle(
                                fontSize: 58,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF202A44),
                                letterSpacing: -2,
                              ),
                            ),
                            TextSpan(
                              text: 'AI',
                              style: TextStyle(
                                fontSize: 58,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF9B7BE8),
                                letterSpacing: -2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 20,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF73738A),
                          ),
                          children: [
                            TextSpan(text: 'Ambalajı '),
                            TextSpan(
                              text: 'tara',
                              style: TextStyle(
                                color: Color(0xFF66BD86),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(text: ', içeriği '),
                            TextSpan(
                              text: 'analiz et.',
                              style: TextStyle(
                                color: Color(0xFF66BD86),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 70),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _loadingDot(const Color(0xFFDDB7F2), 13),
                          const SizedBox(width: 14),
                          _loadingDot(const Color(0xFF6FD39C), 22),
                          const SizedBox(width: 14),
                          _loadingDot(const Color(0xFFDFF7EA), 13),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _softCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.55),
      ),
    );
  }

  Widget _loadingDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.45),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}