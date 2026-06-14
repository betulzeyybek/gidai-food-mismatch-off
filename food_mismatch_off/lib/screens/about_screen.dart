import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBFC),
        elevation: 0,
        foregroundColor: const Color(0xFF4D7C57),
        title: const Text(
          'Hakkında',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFE8578A),
                  size: 42,
                ),
                SizedBox(height: 14),
                Text(
                  'Food Mismatch',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Bu uygulama, gıda ürünlerinde ambalaj görselleri ile içerik bilgileri arasındaki uyumu analiz etmeyi amaçlar.',
                  style: TextStyle(height: 1.45, fontSize: 15),
                ),
                SizedBox(height: 12),
                Text(
                  'Ön yüz görseli nesne tespiti için, içindekiler bölümü ise OCR ile metin okuma için kullanılır.',
                  style: TextStyle(height: 1.45, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
