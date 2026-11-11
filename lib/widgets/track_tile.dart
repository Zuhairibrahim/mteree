import 'package:flutter/material.dart';
import '../models/track.dart';
import '../theme/app_theme.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final bool fav;
  final VoidCallback onTap;
  final VoidCallback onFav;

  const TrackTile({
    super.key,
    required this.track,
    required this.fav,
    required this.onTap,
    required this.onFav,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            color: AppTheme.card,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    // ✅ زر مفضلة أخف من IconButton
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onFav,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          fav ? Icons.favorite : Icons.favorite_border,
                          color: fav ? AppTheme.orange : Colors.white54,
                          size: 22,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // ✅ العنوان
                    Expanded(
                      child: Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // ✅ رقم الشيلة (خفيف + ثابت)
                    _IndexBadge(index: track.index),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IndexBadge extends StatelessWidget {
  final int index;
  const _IndexBadge({required this.index});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [AppTheme.orange, Color(0xFFFFB04A)],
          ),
        ),
        child: Center(
          child: Text(
            "$index",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
