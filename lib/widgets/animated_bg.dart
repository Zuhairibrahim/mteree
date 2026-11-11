import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        final dx = (sin(t * pi * 2) * 0.25);
        final dy = (cos(t * pi * 2) * 0.25);

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(dx, dy),
                  radius: 1.2,
                  colors: const [
                    Color(0xFF1C1C24),
                    AppTheme.bg,
                  ],
                ),
              ),
            ),
            // تموجات خفيفة
            Positioned.fill(
              child: Opacity(
                opacity: 0.08,
                child: CustomPaint(
                  painter: _WavesPainter(progress: t),
                ),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

class _WavesPainter extends CustomPainter {
  final double progress;
  _WavesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 7; i++) {
      final y = size.height * (0.2 + i * 0.1);
      final path = Path()..moveTo(0, y);

      for (double x = 0; x <= size.width; x += 14) {
        final wave =
            sin((x / size.width * 2 * pi) + (progress * 2 * pi) + i) * 10;
        path.lineTo(x, y + wave);
      }
      p.color = Colors.white;
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _WavesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
