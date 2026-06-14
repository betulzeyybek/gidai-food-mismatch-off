import 'package:flutter/material.dart';

class AnalysisGuideScreen extends StatelessWidget {
  const AnalysisGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBFC),
        elevation: 0,
        foregroundColor: const Color(0xFF4D7C57),
        title: const Text(
          'Analiz Rehberi',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          _GuideCard(
            icon: Icons.inventory_2_rounded,
            title: 'Ön yüz fotoğrafı',
            text: 'Ambalajın ön tarafını net, düz ve tam görünecek şekilde çek.',
          ),
          SizedBox(height: 14),
          _GuideCard(
            icon: Icons.receipt_long_rounded,
            title: 'İçindekiler fotoğrafı',
            text: 'Sadece içindekiler bölümünü yakın ve okunaklı şekilde çek.',
          ),
          SizedBox(height: 14),
          _GuideCard(
            icon: Icons.wb_sunny_outlined,
            title: 'Işık ve netlik',
            text: 'Bulanık, karanlık veya parlayan fotoğraflar analiz doğruluğunu düşürür.',
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _GuideCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFE8578A), size: 34),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text(text, style: TextStyle(height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
