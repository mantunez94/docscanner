import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:docscanner/presentation/services/ad_service.dart';

class NativeAdCard extends StatefulWidget {
  final AdService adService;

  const NativeAdCard({super.key, required this.adService});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  @override
  void initState() {
    super.initState();
    widget.adService.addListener(_onAdStateChanged);
    if (!widget.adService.nativeAdLoaded) {
      widget.adService.loadNativeAd();
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
    final ad = widget.adService.nativeAd;
    if (ad == null || !widget.adService.nativeAdLoaded) {
      return const SizedBox.shrink();
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: AdWidget(ad: ad),
    );
  }
}
