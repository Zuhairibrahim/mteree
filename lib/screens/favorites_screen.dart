import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../state/player_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/track_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PlayerController>();
    final favTracks = c.library.where((t) => c.isFav(t.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("المفضلات")),
      body: favTracks.isEmpty
          ? const Center(child: Text("ما عندك مفضلات للحين."))
          : ListView.builder(
        itemCount: favTracks.length,
        itemBuilder: (context, i) {
          final t = favTracks[i];
          return GestureDetector(
            onLongPress: () => _addToPlaylistSheet(context, t),
            child: TrackTile(
              track: t,
              fav: true,
              onFav: () => c.toggleFavorite(t.id),
              onTap: () async {
                // لضمان تشغيلها حتى لو المستخدم حالياً على قائمة ثانية:
                await c.switchPlaylist("المكتبة");
                await c.playTrack(t);
              },
            ),
          );
        },
      ),
    );
  }

  void _addToPlaylistSheet(BuildContext context, Track t) {
    final c = context.read<PlayerController>();
    final names = c.playlists.keys.where((n) => n != "المكتبة").toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "إضافة إلى قائمة: ${t.title}",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (names.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: Text("ما عندك قوائم. أنشئ واحدة من تبويب القوائم."),
                )
              else
                ...names.map((name) {
                  final inIt = c.isInPlaylist(name, t);
                  return ListTile(
                    leading: Icon(
                      inIt ? Icons.check_circle : Icons.add_circle,
                      color: inIt ? AppTheme.orange : null,
                    ),
                    title: Text(name),
                    subtitle: Text(inIt ? "موجودة بالفعل" : "اضغط للإضافة"),
                    onTap: () async {
                      if (!inIt) {
                        await c.addToPlaylist(name, t);
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                }),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }
}
