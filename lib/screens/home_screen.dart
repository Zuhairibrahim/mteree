import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ads/ad_helper.dart';
import '../data/tracks.dart';
import '../state/player_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/track_tile.dart';
import 'now_playing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0; // 0: مكتبة، 1: مفضلة
  String q = "";

  BannerAd? _banner;
  bool _bannerLoaded = false;

  InterstitialAd? _interstitial;
  Timer? _firstAdTimer;
  Timer? _repeatAdTimer;
  bool _isShowingInterstitial = false;

  // Lark-like sheet
  final DraggableScrollableController _sheetC = DraggableScrollableController();
  double _sheetSize = 0.12;

  @override
  void initState() {
    super.initState();

    _loadBanner();
    _loadInterstitial();

    // جدول الإعلانات بعد ما تفتح الشاشة (خفيف)
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _scheduleInterstitials();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final c = context.read<PlayerController>();

      // ✅ حمل المفضلة بالخلف بدون ما يعلق فتح التطبيق
      unawaited(c.loadPlaylists());

      // ✅ جهّز المكتبة بعد أول إطار (تسريع الفتح)
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;

      if (c.library.isEmpty) {
        await c.initLibrary(tracks);
      }
    });
  }

  // ===== Drawer action: Rate app =====
  Future<void> _rateApp() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final packageName = info.packageName;

      final market = Uri.parse('market://details?id=$packageName');
      if (await canLaunchUrl(market)) {
        await launchUrl(market, mode: LaunchMode.externalApplication);
        return;
      }

      final https = Uri.parse(
        'https://play.google.com/store/apps/details?id=$packageName',
      );
      await launchUrl(https, mode: LaunchMode.externalApplication);
    } catch (_) {
      // ignore
    }
  }

  // ===== Ads scheduling =====
  void _scheduleInterstitials() {
    _firstAdTimer?.cancel();
    _repeatAdTimer?.cancel();

    _firstAdTimer = Timer(const Duration(minutes: 1), () {
      _showInterstitialIfReady();
      _repeatAdTimer = Timer.periodic(
        const Duration(minutes: 3),
            (_) => _showInterstitialIfReady(),
      );
    });
  }

  void _loadBanner() {
    _bannerLoaded = false;

    _banner = BannerAd(
      adUnitId: AdHelper.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _bannerLoaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (!mounted) return;
          setState(() => _bannerLoaded = false);
        },
      ),
    )..load();
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  void _showInterstitialIfReady() {
    if (!mounted) return;
    if (_isShowingInterstitial) return;

    if (_interstitial == null) {
      _loadInterstitial();
      return;
    }

    _isShowingInterstitial = true;

    _interstitial!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        _isShowingInterstitial = false;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitial = null;
        _isShowingInterstitial = false;
        _loadInterstitial();
      },
    );

    _interstitial!.show();
  }

  @override
  void dispose() {
    _firstAdTimer?.cancel();
    _repeatAdTimer?.cancel();
    _banner?.dispose();
    _interstitial?.dispose();
    super.dispose();
  }

  // -------- bottom sheets (Sleep timer) --------
  void _openQuickSheet(BuildContext context) {
    final c = context.read<PlayerController>();
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
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text("مؤقت النوم"),
                subtitle: Text(
                  c.sleepRemaining == null
                      ? "غير مفعل"
                      : "متبقي: ${_fmtShort(c.sleepRemaining!)}",
                ),
                onTap: () {
                  Navigator.pop(context);
                  _sleepPicker(context);
                },
              ),
              if (c.sleepRemaining != null)
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text("إلغاء مؤقت النوم"),
                  onTap: () {
                    c.cancelSleepTimer();
                    Navigator.pop(context);
                  },
                ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  void _sleepPicker(BuildContext context) {
    final c = context.read<PlayerController>();
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
              const Text(
                "اختَر مدة مؤقت النوم",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _chip(context, "10 دقائق", const Duration(minutes: 10)),
                  _chip(context, "20 دقيقة", const Duration(minutes: 20)),
                  _chip(context, "30 دقيقة", const Duration(minutes: 30)),
                  _chip(context, "45 دقيقة", const Duration(minutes: 45)),
                  _chip(context, "ساعة", const Duration(hours: 1)),
                ],
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(BuildContext context, String label, Duration d) {
    final c = context.read<PlayerController>();
    return ActionChip(
      label: Text(label),
      onPressed: () {
        c.setSleepTimer(d);
        Navigator.pop(context);
      },
    );
  }

  // -------- widgets --------
  Widget _bannerWidget() {
    if (_banner == null || !_bannerLoaded) return const SizedBox.shrink();
    return SizedBox(
      height: _banner!.size.height.toDouble(),
      width: _banner!.size.width.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }

  Widget _libraryTab(PlayerController c) {
    final list = c.library.where((t) {
      if (q.trim().isEmpty) return true;
      return t.title.contains(q.trim());
    }).toList();

    return Column(
      children: [
        _bannerWidget(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(
            children: [
              const Icon(Icons.library_music, color: AppTheme.orange),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final res = await showSearch<String?>(
                      context: context,
                      delegate: _ArabicSearchDelegate(initial: q),
                    );
                    if (res != null) setState(() => q = res);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search,
                            size: 20, color: Colors.white54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            q.isEmpty ? "ابحث عن شيلة..." : q,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: "خيارات",
                onPressed: () => _openQuickSheet(context),
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text("ما فيه نتائج."))
              : ListView.builder(
            padding: const EdgeInsets.only(bottom: 180),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final t = list[i];
              return TrackTile(
                track: t,
                fav: c.isFav(t.id),
                onFav: () => c.toggleFavorite(t.id),
                onTap: () => c.playTrack(t),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _favoritesTab(PlayerController c) {
    final favTracks = c.library.where((t) => c.isFav(t.id)).toList();

    return Column(
      children: [
        _bannerWidget(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "المفضلة",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: "خيارات",
                onPressed: () => _openQuickSheet(context),
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
        Expanded(
          child: favTracks.isEmpty
              ? const Center(child: Text("ما عندك مفضلات للحين."))
              : ListView.builder(
            padding: const EdgeInsets.only(bottom: 180),
            itemCount: favTracks.length,
            itemBuilder: (context, i) {
              final t = favTracks[i];
              return TrackTile(
                track: t,
                fav: true,
                onFav: () => c.toggleFavorite(t.id),
                onTap: () => c.playTrack(t),
              );
            },
          ),
        ),
      ],
    );
  }

  // ====== Lark-style draggable player sheet (FIXED) ======
  Widget _playerSheet(PlayerController c) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (n) {
        if (!mounted) return false;
        setState(() => _sheetSize = n.extent);
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _sheetC,
        initialChildSize: 0.12,
        minChildSize: 0.12,
        maxChildSize: 0.92,
        snap: true,
        snapSizes: const [0.12, 0.55, 0.92],
        builder: (context, scrollController) {
          final isMini = _sheetSize <= 0.16;

          return Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.bg.withValues(alpha: 0.98),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(22)),
                border: Border.all(color: Colors.white10),
              ),

              // ✅ لازم Scrollable مربوط بالـ scrollController
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                physics: const ClampingScrollPhysics(),
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: isMini ? 92 : 650,
                    child: isMini
                        ? NowPlayingMiniBar(
                      controller: c,
                      onTapExpand: () {
                        _sheetC.animateTo(
                          0.55,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        );
                      },
                    )
                        : const NowPlayingContentView(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PlayerController>();

    final pages = [
      _libraryTab(c),
      _favoritesTab(c),
    ];

    return Scaffold(
      drawer: Drawer(
        backgroundColor: AppTheme.card,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "AL-Shikh",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Colors.white12),
              ListTile(
                leading: const Icon(Icons.star_rate_rounded,
                    color: AppTheme.orange),
                title: const Text("قيمنا + تعليق"),
                onTap: () async {
                  Navigator.pop(context);
                  await _rateApp();
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  "SHELAT 2026",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.25)),
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text("شيلات 2026"),
        leading: Builder(
          builder: (ctx) => IconButton(
            tooltip: "القائمة",
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: KeyedSubtree(
              key: ValueKey(tab),
              child: pages[tab],
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _playerSheet(c),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab,
        onTap: (i) => setState(() => tab = i),
        backgroundColor: AppTheme.bg,
        selectedItemColor: AppTheme.orange,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: "المكتبة",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "المفضلة",
          ),
        ],
      ),
    );
  }

  static String _fmtShort(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? "$h:$m:$s" : "$m:$s";
  }
}

class _ArabicSearchDelegate extends SearchDelegate<String?> {
  _ArabicSearchDelegate({required String initial}) {
    query = initial;
  }

  @override
  String get searchFieldLabel => "ابحث عن شيلة...";

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = "",
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, query),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(child: Text("اكتب اسم الشيلة واضغط رجوع ✅"));
  }
}
