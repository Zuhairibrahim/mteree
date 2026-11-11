import 'package:flutter/material.dart' hide RepeatMode;
import '../state/player_controller.dart';
import '../theme/app_theme.dart';

class PlayerBar extends StatelessWidget {
  final PlayerController controller;
  const PlayerBar({super.key, required this.controller});

  String _repeatLabel(RepeatMode m) {
    switch (m) {
      case RepeatMode.off:
        return "تكرار: إيقاف";
      case RepeatMode.all:
        return "تكرار: الكل";
      case RepeatMode.one:
        return "تكرار: واحد";
    }
  }

  IconData _repeatIcon(RepeatMode m) {
    switch (m) {
      case RepeatMode.off:
        return Icons.repeat;
      case RepeatMode.all:
        return Icons.repeat;
      case RepeatMode.one:
        return Icons.repeat_one;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = controller.current;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq, color: AppTheme.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t?.title ?? "قم باختيار شيلة لتشغيلها",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (controller.sleepRemaining != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    _fmt(controller.sleepRemaining!),
                    style: const TextStyle(
                        color: AppTheme.orange, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // أزرار التحكم
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: "عشوائي",
                onPressed: t == null ? null : controller.toggleShuffle,
                icon: Icon(
                  Icons.shuffle,
                  color: controller.shuffleEnabled
                      ? AppTheme.orange
                      : Colors.white54,
                ),
              ),
              IconButton(
                tooltip: "السابق",
                onPressed: t == null ? null : controller.previous,
                icon: const Icon(Icons.skip_previous, size: 30),
              ),
              IconButton(
                tooltip: controller.isPlaying ? "إيقاف مؤقت" : "تشغيل",
                onPressed: t == null ? null : controller.togglePlayPause,
                icon: Icon(
                  controller.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  size: 48,
                  color: t == null ? Colors.white24 : AppTheme.orange,
                ),
              ),
              IconButton(
                tooltip: "التالي",
                onPressed: t == null ? null : controller.next,
                icon: const Icon(Icons.skip_next, size: 30),
              ),
              IconButton(
                tooltip: _repeatLabel(controller.repeatMode),
                onPressed: t == null ? null : controller.cycleRepeat,
                icon: Icon(
                  _repeatIcon(controller.repeatMode),
                  color: controller.repeatMode == RepeatMode.off
                      ? Colors.white54
                      : AppTheme.orange,
                ),
              ),
            ],
          ),

          // السلايدر
          StreamBuilder(
            stream: controller.positionStream,
            builder: (context, snapPos) {
              final pos = snapPos.data ?? Duration.zero;
              return StreamBuilder(
                stream: controller.durationStream,
                builder: (context, snapDur) {
                  final dur = snapDur.data ?? const Duration(seconds: 1);
                  final maxMs =
                      dur.inMilliseconds <= 0 ? 1 : dur.inMilliseconds;
                  final value =
                      (pos.inMilliseconds / maxMs).clamp(0.0, 1.0).toDouble();

                  return Slider(
                    value: value,
                    onChanged: t == null
                        ? null
                        : (v) {
                            controller.seek(
                                Duration(milliseconds: (maxMs * v).toInt()));
                          },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? "$h:$m:$s" : "$m:$s";
  }
}
