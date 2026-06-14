import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'result_screen.dart';
import '../services/saved_images_service.dart';
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _log(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(message);
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      _log('📸 Bulunan kamera sayısı: ${cameras.length}');

      if (cameras.isEmpty) {
        _log('❌ Kamera bulunamadı!');
        if (!mounted) return;

        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Kamera Hatası'),
            content: const Text(
              'Bu cihazda kamera bulunamadı.\n\n'
              "iOS Simulator'de kamera çalışmaz, lütfen gerçek iPhone kullanın.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Dialog kapat
                  Navigator.pop(context); // Kamera ekranını kapat
                },
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
        return;
      }

      _log('✅ Kamera başlatılıyor...');
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
      );

      await controller.initialize();

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isInitialized = true;
      });

      _log('✅ Kamera hazır!');
    } catch (e) {
      _log('❌ Kamera hatası detayı: $e');
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kamera Hatası'),
          content: Text(
            'Hata: $e\n\n'
            "iOS Simulator'de kamera çalışmaz.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() => _isLoading = true);

    try {
     final XFile photo = await controller.takePicture();

// ✅ Uygulama içine kopyala/kaydet
final savedPath = await SavedImagesService.saveToAppFolder(photo.path);

if (!mounted) return;
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => ResultScreen(imagePath: savedPath),
  ),
);
    } catch (e) {
      _log('Fotoğraf çekme hatası: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Fotoğraf Çek'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isInitialized && controller != null
          ? Stack(
              children: [
                SizedBox.expand(child: CameraPreview(controller)),
                Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF7CB68A),
            width: 4,
          ),
          borderRadius: BorderRadius.circular(26),
        ),
      ),

      const SizedBox(height: 18),

      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Ürünü çerçevenin içine yerleştir',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  ),
),

                if (_isLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),

                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _isLoading ? null : _takePicture,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 4,
                          ),
                        ),
                        child: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(15),
                                child: CircularProgressIndicator(strokeWidth: 3),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Kamera hazırlanıyor...',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                  ),
                ],
              ),
            ),
    );
  }
}
