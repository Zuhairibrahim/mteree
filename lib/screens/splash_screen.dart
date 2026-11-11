import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // بعد أول فريم: جهّز الصورة ثم روح للـ Home بسرعة
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ✅ جهّز اللوقو (ما يعلق الواجهة)
      try {
        await precacheImage(
          const AssetImage('assets/images/logo.jpg'),
          context,
        );
      } catch (_) {}

      // ✅ خليه يظهر لحظة بسيطة فقط (بدل 2 ثانية)
      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted || _navigated) return;
      _navigated = true;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (_, a, __) =>
              FadeTransition(opacity: a, child: const HomeScreen()),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.25),
            radius: 1.1,
            colors: [Color(0xFF1A1A22), AppTheme.bg],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ صورة دائرية بدل الأيقونة الافتراضية
              ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "شيلات 2026",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                "منوعه كل جديد",
                style: TextStyle(fontSize: 14, color: AppTheme.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
