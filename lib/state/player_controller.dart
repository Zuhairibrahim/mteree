import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';

enum RepeatMode { off, one, all }

class PlayerController extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  // مكتبة
  List<Track> library = [];

  // قوائم المستخدم (اسم -> قائمة Tracks)
  final Map<String, List<Track>> playlists = {
    "المكتبة": [],
  };

  // الحالة الحالية
  String currentPlaylist = "المكتبة";
  Track? current;
  int? currentIndex;

  // تشغيل
  bool shuffleEnabled = false;
  RepeatMode repeatMode = RepeatMode.off;
  bool get isPlaying => _player.playing;

  // مفضلة
  final Set<String> favorites = {};

  // مؤقت النوم
  Timer? _sleepTimer;
  Duration? sleepRemaining;

  // Streams
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  List<Track> get activeList => playlists[currentPlaylist] ?? const [];

  // ====== Storage keys ======
  static const _kPlaylistsJson = 'playlists_json_v1';
  static const _kFavorites = 'favorites_v1';
  static const _kCurrentPlaylist = 'current_playlist_v1';

  // -------- init --------
  Future<void> initLibrary(List<Track> tracks) async {
    library = tracks;

    // حافظ على "المكتبة" دائمًا
    playlists["المكتبة"] = tracks;

    // لو ما فيه قوائم محفوظة سابقًا، خلي الحالي مكتبة
    if (!playlists.containsKey(currentPlaylist)) {
      currentPlaylist = "المكتبة";
    }

    await _buildAudioSourceFor(currentPlaylist);
    notifyListeners();

    // تحديث current عند تغيّر index
    _player.currentIndexStream.listen((idx) {
      if (idx == null) return;
      currentIndex = idx;
      final list = activeList;
      if (idx >= 0 && idx < list.length) current = list[idx];
      notifyListeners();
    });
  }

  Future<void> _buildAudioSourceFor(String name) async {
    currentPlaylist = name;
    final list = playlists[name] ?? const [];

    final source = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: list.map((t) => AudioSource.asset(t.assetPath)).toList(),
    );

    await _player.setAudioSource(source, initialIndex: 0, preload: false);
    await _player.setShuffleModeEnabled(shuffleEnabled);
    await _player.setLoopMode(_toLoopMode(repeatMode));

    currentIndex = list.isNotEmpty ? 0 : null;
    current = list.isNotEmpty ? list[0] : null;
  }

  LoopMode _toLoopMode(RepeatMode m) {
    switch (m) {
      case RepeatMode.off:
        return LoopMode.off;
      case RepeatMode.one:
        return LoopMode.one;
      case RepeatMode.all:
        return LoopMode.all;
    }
  }

  // ====== Persistence (Playlists + Favorites + Current playlist) ======
  Future<void> loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();

    // favorites
    final fav = prefs.getStringList(_kFavorites) ?? const <String>[];
    favorites
      ..clear()
      ..addAll(fav);

    // current playlist
    final savedCurrent = prefs.getString(_kCurrentPlaylist);
    if (savedCurrent != null && savedCurrent.trim().isNotEmpty) {
      currentPlaylist = savedCurrent;
    }

    // playlists by track IDs
    final jsonStr = prefs.getString(_kPlaylistsJson);
    if (jsonStr == null || jsonStr.trim().isEmpty) return;

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    // لا تمس "المكتبة" هنا (بتتعبّى من initLibrary)
    decoded.forEach((name, value) {
      if (name == "المكتبة") return;
      if (value is List) {
        // مؤقتًا نخزّن IDs ثم نحولها لـ Tracks بعد ما تكون المكتبة جاهزة
        final ids = value.map((e) => e.toString()).toList();
        playlists[name] = _tracksFromIds(ids);
      }
    });

    // تأكيد وجود الحالي
    if (!playlists.containsKey(currentPlaylist)) {
      currentPlaylist = "المكتبة";
    }

    notifyListeners();
  }

  Future<void> savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();

    // حفظ favorites
    await prefs.setStringList(_kFavorites, favorites.toList());

    // حفظ current playlist
    await prefs.setString(_kCurrentPlaylist, currentPlaylist);

    // حفظ القوائم (ما عدا المكتبة) كـ IDs
    final Map<String, List<String>> out = {};
    playlists.forEach((name, list) {
      if (name == "المكتبة") return;
      out[name] = list.map((t) => t.id).toList();
    });

    await prefs.setString(_kPlaylistsJson, jsonEncode(out));
  }

  List<Track> _tracksFromIds(List<String> ids) {
    if (library.isEmpty) return [];
    final byId = {for (final t in library) t.id: t};
    final result = <Track>[];
    for (final id in ids) {
      final t = byId[id];
      if (t != null) result.add(t);
    }
    return result;
  }

  // -------- playback controls --------
  Future<void> playAt(int index) async {
    final list = activeList;
    if (list.isEmpty) return;
    if (index < 0 || index >= list.length) return;

    await _player.seek(Duration.zero, index: index);
    await _player.play();
    currentIndex = index;
    current = list[index];
    notifyListeners();
  }

  Future<void> playTrack(Track t) async {
    final idx = activeList.indexWhere((x) => x.id == t.id);
    if (idx == -1) return;
    await playAt(idx);
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    notifyListeners();
  }

  Future<void> next() async {
    await _player.seekToNext();
  }

  Future<void> previous() async {
    await _player.seekToPrevious();
  }

  Future<void> seek(Duration d) => _player.seek(d);

  Future<void> toggleShuffle() async {
    shuffleEnabled = !shuffleEnabled;
    await _player.setShuffleModeEnabled(shuffleEnabled);
    if (shuffleEnabled) await _player.shuffle();
    notifyListeners();
  }

  Future<void> cycleRepeat() async {
    repeatMode = switch (repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    await _player.setLoopMode(_toLoopMode(repeatMode));
    notifyListeners();
  }

  // -------- playlists (user managed) --------
  bool canDeletePlaylist(String name) => name != "المكتبة";

  void createPlaylist(String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    if (playlists.containsKey(n)) return;
    playlists[n] = [];
    notifyListeners();
    unawaited(savePlaylists());
  }

  void renamePlaylist(String oldName, String newName) {
    if (oldName == "المكتبة") return;
    final n = newName.trim();
    if (n.isEmpty) return;
    if (!playlists.containsKey(oldName)) return;
    if (playlists.containsKey(n)) return;

    final items = playlists.remove(oldName)!;
    playlists[n] = items;

    if (currentPlaylist == oldName) {
      currentPlaylist = n;
    }
    notifyListeners();
    unawaited(savePlaylists());
  }

  Future<void> deletePlaylist(String name) async {
    if (!canDeletePlaylist(name)) return;
    if (!playlists.containsKey(name)) return;

    playlists.remove(name);

    if (currentPlaylist == name) {
      await switchPlaylist("المكتبة", autoplay: false);
    } else {
      notifyListeners();
    }
    unawaited(savePlaylists());
  }

  bool isInPlaylist(String name, Track t) {
    final list = playlists[name];
    if (list == null) return false;
    return list.any((x) => x.id == t.id);
  }

  Future<void> addToPlaylist(String name, Track t) async {
    if (!playlists.containsKey(name)) return;
    final list = playlists[name]!;
    if (list.any((x) => x.id == t.id)) return;
    list.add(t);

    if (currentPlaylist == name) {
      await _buildAudioSourceFor(name);
    }
    notifyListeners();
    unawaited(savePlaylists());
  }

  Future<void> removeFromPlaylist(String name, Track t) async {
    if (!playlists.containsKey(name)) return;
    final list = playlists[name]!;
    list.removeWhere((x) => x.id == t.id);

    if (currentPlaylist == name) {
      await _buildAudioSourceFor(name);
    }
    notifyListeners();
    unawaited(savePlaylists());
  }

  Future<void> switchPlaylist(String name, {bool autoplay = false}) async {
    if (!playlists.containsKey(name)) return;
    await _buildAudioSourceFor(name);
    notifyListeners();
    unawaited(savePlaylists());

    if (autoplay && activeList.isNotEmpty) {
      await _player.play();
      notifyListeners();
    }
  }

  // -------- sleep timer --------
  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepRemaining = null;
    notifyListeners();
  }

  void setSleepTimer(Duration duration) {
    cancelSleepTimer();
    sleepRemaining = duration;
    notifyListeners();

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (sleepRemaining == null) return;
      final left = sleepRemaining! - const Duration(seconds: 1);
      if (left <= Duration.zero) {
        cancelSleepTimer();
        await _player.stop();
        notifyListeners();
        return;
      }
      sleepRemaining = left;
      notifyListeners();
    });
  }

  // -------- favorites --------
  void toggleFavorite(String id) {
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    notifyListeners();
    unawaited(savePlaylists());
  }

  bool isFav(String id) => favorites.contains(id);

  @override
  void dispose() {
    cancelSleepTimer();
    _player.dispose();
    super.dispose();
  }
}
