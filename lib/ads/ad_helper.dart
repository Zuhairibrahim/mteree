import 'dart:io';
import 'package:flutter/foundation.dart';

class AdHelper {
  // ✅ IDs حق حسابك (Production)
  static const String _androidAppId =
      'ca-app-pub-1396394529471927~3219944646';

  static const String _androidBannerId =
      'ca-app-pub-1396394529471927/9426260348';

  static const String _androidInterstitialId =
      'ca-app-pub-1396394529471927/8098874414';

  // ✅ IDs تجريبية من Google (Debug)
  static const String _testBannerId =
      'ca-app-pub-3940256099942544/6300978111';

  static const String _testInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';

  /// ✅ للتشخيص: خليها true إذا تبي "تجبر" الإعلانات التجريبية حتى في Release
  static const bool forceTestAds = false;

  /// App ID (موجود بالـ AndroidManifest، هنا فقط للمرجع)
  static String get appId {
    if (!Platform.isAndroid) {
      throw UnsupportedError('AdMob is supported on Android only in this app');
    }
    return _androidAppId;
  }

  static bool get _useTestAds => !kReleaseMode || forceTestAds;

  /// Banner Ad Unit ID
  static String get bannerUnitId {
    if (!Platform.isAndroid) {
      throw UnsupportedError('AdMob is supported on Android only in this app');
    }
    return _useTestAds ? _testBannerId : _androidBannerId;
  }

  /// Interstitial Ad Unit ID
  static String get interstitialUnitId {
    if (!Platform.isAndroid) {
      throw UnsupportedError('AdMob is supported on Android only in this app');
    }
    return _useTestAds ? _testInterstitialId : _androidInterstitialId;
  }
}
