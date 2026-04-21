import 'package:aun_reqstudio/core/services/ad_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeListAdTile extends StatefulWidget {
  const NativeListAdTile({
    super.key,
    required this.templateStyle,
    required this.labelColor,
    required this.borderColor,
    required this.chromeColor,
    required this.appearanceKey,
    this.height = 132,
  });

  final NativeTemplateStyle templateStyle;
  final Color labelColor;
  final Color borderColor;
  final Color chromeColor;
  final Object appearanceKey;
  final double height;

  @override
  State<NativeListAdTile> createState() => _NativeListAdTileState();
}

class _NativeListAdTileState extends State<NativeListAdTile> {
  NativeAd? _nativeAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  @override
  void didUpdateWidget(covariant NativeListAdTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appearanceKey != widget.appearanceKey) {
      _reloadNativeAd();
    }
  }

  void _loadNativeAd() {
    _nativeAd = AdService.instance.createInlineNativeAd(
      templateStyle: widget.templateStyle,
      onAdLoaded: (_) {
        if (!mounted) return;
        setState(() => _loaded = true);
      },
      onAdFailedToLoad: (_, __) {
        if (!mounted) return;
        setState(() {
          _loaded = false;
          _nativeAd = null;
        });
      },
    );
    _nativeAd?.load();
  }

  void _reloadNativeAd() {
    _nativeAd?.dispose();
    setState(() {
      _loaded = false;
      _nativeAd = null;
    });
    _loadNativeAd();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: widget.chromeColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.borderColor.withValues(alpha: 0.6)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sponsored',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: widget.labelColor,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: widget.height,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AdWidget(ad: _nativeAd!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomBannerAdSection extends StatefulWidget {
  const BottomBannerAdSection({super.key});

  @override
  State<BottomBannerAdSection> createState() => _BottomBannerAdSectionState();
}

class _BottomBannerAdSectionState extends State<BottomBannerAdSection> {
  BannerAd? _bannerAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = AdService.instance.createBottomBannerAd(
      onAdLoaded: (_) {
        if (!mounted) return;
        setState(() => _loaded = true);
      },
      onAdFailedToLoad: (_, __) {
        if (!mounted) return;
        setState(() {
          _loaded = false;
          _bannerAd = null;
        });
      },
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Center(
          child: SizedBox(
            height: _bannerAd!.size.height.toDouble(),
            width: _bannerAd!.size.width.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ),
      ),
    );
  }
}
