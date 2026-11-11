import 'dart:math';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:provider/provider.dart';

import '../state/player_controller.dart';
import '../theme/app_theme.dart';

/// (اختياري) صفحة مستقلة لو احتجتها.
/// لكن الآن المشغل الأساسي داخل Draggable sheet في HomeScreen.
class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: NowPlayingContentView()),
    );
  }
}

/// ✅ Full content داخل الشيت (Lark style)
class NowPlayingContentView extends StatelessWidget {
  const NowPlayingContentView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PlayerController>();
    final t = c.current;

    return Stack(
      children: [
        const _CinematicBackground(),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),

              // ✅ صورة دائرية تدور وقت التشغيل
              Center(
                child: _RotatingAvatar(
                  isPlaying: c.isPlaying,
                  size: 210,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                t?.title ?? "اختر شيلة من المكتبة",
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "SHELAT 2026",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 14),

              // موجات بسيطة (شكل فقط)
              const _WaveBar(),
              const SizedBox(height: 14),

              // سلايدر + وقت/مدة
              _ProgressSlider(controller: c),
              const SizedBox(height: 6),

              _Controls(controller: c),

              const SizedBox(height: 6),
            ],
          ),
        ),
      ],
    );
  }
}

/// ✅ Mini bar مثل Lark: صورة دائرية + عنوان + play/pause
class NowPlayingMiniBar extends StatelessWidget {
  final PlayerController controller;
  final VoidCallback onTapExpand;

  const NowPlayingMiniBar({
    super.key,
    required this.controller,
    required this.onTapExpand,
  });

  @override
  Widget build(BuildContext context) {
    final t = controller.current;

    return InkWell(
      onTap: onTapExpand,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Row(
          children: [
            _RotatingAvatar(
              isPlaying: controller.isPlaying,
              size: 46,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t?.title ?? "اختر شيلة من المكتبة",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StreamBuilder<Duration>(
                    stream: controller.positionStream,
                    initialData: Duration.zero,
                    builder: (_, snap) {
                      final pos = snap.data ?? Duration.zero;
                      return Text(
                        _fmt(pos),
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: controller.isPlaying ? "إيقاف" : "تشغيل",
              onPressed: controller.current == null
                  ? null
                  : controller.togglePlayPause,
              icon: Icon(
                controller.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                size: 44,
                color: controller.current == null
                    ? Colors.white24
                    : AppTheme.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? "$h:$m:$s" : "$m:$s";
  }
}

/// ✅ صورة دائرية تدور وقت التشغيل فقط
class _RotatingAvatar extends StatefulWidget {
  final bool isPlaying;
  final double size;

  const _RotatingAvatar({
    required this.isPlaying,
    required this.size,
  });

  @override
  State<_RotatingAvatar> createState() => _RotatingAvatarState();
}

class _RotatingAvatarState extends State<_RotatingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    if (widget.isPlaying) {
      _c.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _RotatingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _c.repeat();
      } else {
        _c.stop();
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final angle = _c.value * pi * 2;
        return Transform.rotate(
          angle: angle,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.orange.withOpacity(0.22),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: Colors.white12, width: 2),
              image: const DecorationImage(
                image: AssetImage('assets/images/logo.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CinematicBackground extends StatefulWidget {
  const _CinematicBackground();

  @override
  State<_CinematicBackground> createState() => _CinematicBackgroundState();
}

class _CinematicBackgroundState extends State<_CinematicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 9))
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
        final dx = sin(t * pi * 2) * 0.35;
        final dy = cos(t * pi * 2) * 0.35;
        return Container(
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
          child: CustomPaint(painter: _FogPainter(progress: t)),
        );
      },
    );
  }
}

class _FogPainter extends CustomPainter {
  final double progress;
  _FogPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.04);
    for (int i = 0; i < 12; i++) {
      final x = (size.width * (i / 11)) + sin(progress * pi * 2 + i) * 18;
      final y = size.height * 0.18 + (i * 28) + cos(progress * pi * 2 + i) * 10;
      canvas.drawCircle(Offset(x, y), 60, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FogPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _WaveBar extends StatefulWidget {
  const _WaveBar();

  @override
  State<_WaveBar> createState() => _WaveBarState();
}

class _WaveBarState extends State<_WaveBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(18, (i) {
              final h = 8 + (sin((t * pi * 2) + i * 0.6).abs() * 18);
              return Container(
                width: 5,
                height: h,
                decoration: BoxDecoration(
                  color: i % 3 == 0
                      ? AppTheme.orange
                      : Colors.white.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _ProgressSlider extends StatelessWidget {
  final PlayerController controller;
  const _ProgressSlider({required this.controller});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: controller.positionStream,
      initialData: Duration.zero,
      builder: (context, snapPos) {
        final pos = snapPos.data ?? Duration.zero;

        return StreamBuilder<Duration?>(
          stream: controller.durationStream,
          builder: (context, snapDur) {
            final dur = snapDur.data;
            final durMs = (dur == null || dur.inMilliseconds <= 0)
                ? null
                : dur.inMilliseconds;

            final maxMs = durMs ?? 1;
            final v = (pos.inMilliseconds / maxMs).clamp(0.0, 1.0).toDouble();

            return Column(
              children: [
                Slider(
                  value: v,
                  onChanged: (controller.current == null || durMs == null)
                      ? null
                      : (x) => controller.seek(
                            Duration(milliseconds: (maxMs * x).toInt()),
                          ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(pos),
                        style: const TextStyle(color: AppTheme.muted)),
                    Text(durMs == null ? "--:--" : _fmt(dur!),
                        style: const TextStyle(color: AppTheme.muted)),
                  ],
                )
              ],
            );
          },
        );
      },
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? "$h:$m:$s" : "$m:$s";
  }
}

class _Controls extends StatelessWidget {
  final PlayerController controller;
  const _Controls({required this.controller});

  IconData _repeatIcon(RepeatMode m) =>
      m == RepeatMode.one ? Icons.repeat_one : Icons.repeat;

  @override
  Widget build(BuildContext context) {
    final disabled = controller.current == null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          tooltip: "عشوائي",
          onPressed: disabled ? null : controller.toggleShuffle,
          icon: Icon(
            Icons.shuffle,
            color: controller.shuffleEnabled ? AppTheme.orange : Colors.white54,
          ),
        ),
        IconButton(
          tooltip: "السابق",
          onPressed: disabled ? null : controller.previous,
          icon: const Icon(Icons.skip_previous, size: 34),
        ),
        IconButton(
          tooltip: controller.isPlaying ? "إيقاف مؤقت" : "تشغيل",
          onPressed: disabled ? null : controller.togglePlayPause,
          icon: Icon(
            controller.isPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_fill,
            size: 64,
            color: disabled ? Colors.white24 : AppTheme.orange,
          ),
        ),
        IconButton(
          tooltip: "التالي",
          onPressed: disabled ? null : controller.next,
          icon: const Icon(Icons.skip_next, size: 34),
        ),
        IconButton(
          tooltip: "تكرار",
          onPressed: disabled ? null : controller.cycleRepeat,
          icon: Icon(
            _repeatIcon(controller.repeatMode),
            color: controller.repeatMode == RepeatMode.off
                ? Colors.white54
                : AppTheme.orange,
          ),
        ),
      ],
    );
  }
}

String _fmt(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  final h = d.inHours;
  return h > 0 ? "$h:$m:$s" : "$m:$s";
}
