import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:docscanner/presentation/services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  final AdService adService;

  const BannerAdWidget({super.key, required this.adService});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  @override
  void initState() {
    super.initState();
    widget.adService.addListener(_onAdStateChanged);
    if (!widget.adService.bannerAdLoaded) {
      widget.adService.loadBannerAd();
    }
  }

  void _onAdStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.adService.removeListener(_onAdStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.adService.bannerAd;
    if (ad == null || !widget.adService.bannerAdLoaded) {
      return const SizedBox(height: 50);
    }
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Center(
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
