import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:docscanner/presentation/services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  final AdService adService;
  final VoidCallback? onDismissed;
  final bool visible;

  const BannerAdWidget({
    super.key,
    required this.adService,
    this.onDismissed,
    this.visible = true,
  });

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
    if (!widget.visible) return const SizedBox(height: 50);

    final ad = widget.adService.bannerAd;
    if (ad == null || !widget.adService.bannerAdLoaded) {
      return const SizedBox(height: 50);
    }
    return Container(
      height: ad.size.height.toDouble() + 8,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Center(
            child: SizedBox(
              width: ad.size.width.toDouble(),
              height: ad.size.height.toDouble(),
              child: AdWidget(ad: ad),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => widget.onDismissed?.call(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface.withAlpha(120),
            ),
          ),
        ],
      ),
    );
  }
}
