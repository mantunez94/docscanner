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
    final nativeAd = widget.adService.nativeAd;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerLow,
        child: Stack(
          children: [
            if (nativeAd != null && widget.adService.nativeAdLoaded)
              Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: double.infinity,
                  child: AdWidget(ad: nativeAd),
                ),
              )
            else
              const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
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
            if (nativeAd == null || !widget.adService.nativeAdLoaded)
              Positioned(
                bottom: 8,
                right: 8,
                child: TextButton(
                  onPressed: widget.onDismissed,
                  child: const Text('Cerrar'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
