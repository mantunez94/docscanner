import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
const String testNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

String get _bannerAdUnitId {
  const prodId = String.fromEnvironment('AD_BANNER_UNIT_ID');
  if (prodId.isNotEmpty) return prodId;
  return testBannerAdUnitId;
}

String get _nativeAdUnitId {
  const prodId = String.fromEnvironment('AD_NATIVE_UNIT_ID');
  if (prodId.isNotEmpty) return prodId;
  return testNativeAdUnitId;
}

final showAdBannerProvider = StateProvider<bool>((ref) => true);
final showPostSaveAdProvider = StateProvider<bool>((ref) => false);

class AdService extends ChangeNotifier {
  BannerAd? _bannerAd;
  NativeAd? _nativeAd;
  bool _bannerAdLoaded = false;
  bool _nativeAdLoaded = false;

  bool get bannerAdLoaded => _bannerAdLoaded;
  bool get nativeAdLoaded => _nativeAdLoaded;
  BannerAd? get bannerAd => _bannerAd;
  NativeAd? get nativeAd => _nativeAd;

  void loadBannerAd() {
    if (_bannerAd != null) return;
    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _bannerAdLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (_, __) {},
      ),
    );
    _bannerAd!.load();
  }

  void loadNativeAd() {
    if (_nativeAd != null) return;
    _nativeAd = NativeAd(
      adUnitId: _nativeAdUnitId,
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
      ),
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          _nativeAdLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (_, __) {},
      ),
    );
    _nativeAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _nativeAd?.dispose();
    super.dispose();
  }
}

final adServiceProvider = ChangeNotifierProvider<AdService>((ref) {
  return AdService();
});
