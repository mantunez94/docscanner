import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:docscanner/presentation/services/ad_service.dart';

class PostSaveAdCard extends StatefulWidget {
  final AdService adService;
  final VoidCallback onDismissed;

  const PostSaveAdCard({
    super.key,
    required this.adService,
    required this.onDismissed,
  });

  @override
  State<PostSaveAdCard> createState() => _PostSaveAdCardState();
}

class _PostSaveAdCardState extends State<PostSaveAdCard> {
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
    final theme = Theme.of(context);
    final loaded = widget.adService.nativeAdLoaded;
    final nativeAd = widget.adService.nativeAd;
    final ready = loaded && nativeAd != null;

    return GestureDetector(
      onTap: () {},
      child: Container(
        height: ready ? 280 : 60,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Stack(
          children: [
            if (ready)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8, right: 40),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AdWidget(ad: nativeAd),
                ),
              )
            else
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: widget.onDismissed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface.withAlpha(200),
                  foregroundColor: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
