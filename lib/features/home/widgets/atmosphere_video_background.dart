import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/atmosphere_theme.dart';
import 'atmosphere_background.dart';

/// Sky layer: bundled looping MP4 (offline-safe) + live particle overlay.
/// Network CDNs were blocked (403); assets always load on-device.
class AtmosphereVideoBackground extends StatefulWidget {
  const AtmosphereVideoBackground({
    super.key,
    required this.palette,
    required this.sky,
    required this.period,
  });

  final AtmospherePalette palette;
  final SkyCondition sky;
  final SkyPeriod period;

  @override
  State<AtmosphereVideoBackground> createState() =>
      _AtmosphereVideoBackgroundState();
}

class _AtmosphereVideoBackgroundState extends State<AtmosphereVideoBackground> {
  VideoPlayerController? _controller;
  var _ready = false;
  String? _activeKey;

  static String _assetFor(SkyPeriod period, SkyCondition sky) {
    if (sky == SkyCondition.thunder) return 'assets/videos/sky_thunder.mp4';
    if (sky == SkyCondition.heavyRain ||
        sky == SkyCondition.rain ||
        sky == SkyCondition.drizzle) {
      return 'assets/videos/sky_rain.mp4';
    }
    if (sky == SkyCondition.fog) return 'assets/videos/sky_fog.mp4';
    if (sky == SkyCondition.overcast ||
        sky == SkyCondition.cloudy ||
        sky == SkyCondition.partlyCloudy) {
      return 'assets/videos/sky_cloudy.mp4';
    }
    if (sky == SkyCondition.snow) return 'assets/videos/sky_cloudy.mp4';
    switch (period) {
      case SkyPeriod.sunrise:
      case SkyPeriod.predawn:
        return 'assets/videos/sky_sunrise.mp4';
      case SkyPeriod.sunset:
      case SkyPeriod.goldenHour:
      case SkyPeriod.dusk:
        return 'assets/videos/sky_sunset.mp4';
      case SkyPeriod.night:
      case SkyPeriod.midnight:
      case SkyPeriod.evening:
        return 'assets/videos/sky_night.mp4';
      case SkyPeriod.midday:
      case SkyPeriod.morning:
      case SkyPeriod.afternoon:
        return 'assets/videos/sky_day.mp4';
    }
  }

  Future<void> _load(String asset) async {
    if (_activeKey == asset && _ready) return;
    _activeKey = asset;
    final old = _controller;
    _controller = null;
    if (mounted) setState(() => _ready = false);
    await old?.dispose();
    try {
      final c = VideoPlayerController.asset(asset);
      _controller = c;
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      debugPrint('Atmosphere video load failed: $asset → $e');
      if (!mounted) return;
      setState(() => _ready = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load(_assetFor(widget.period, widget.sky));
  }

  @override
  void didUpdateWidget(covariant AtmosphereVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period || oldWidget.sky != widget.sky) {
      _load(_assetFor(widget.period, widget.sky));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Palette gradient (always)
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [p.top, p.mid, p.bottom],
            ),
          ),
        ),
        // Bundled looping video
        if (_ready && _controller != null && _controller!.value.isInitialized)
          Opacity(
            opacity: 0.55,
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
        // Live particles: rain, stars, sun/moon, clouds (always on)
        AtmosphereBackground(
          particlesOnly: true,
          palette: p,
          sky: widget.sky,
          period: widget.period,
        ),
        // Readability veil
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.15),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.45),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
