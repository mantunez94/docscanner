import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
const String testNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

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
      adUnitId: testBannerAdUnitId,
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
      adUnitId: testNativeAdUnitId,
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
