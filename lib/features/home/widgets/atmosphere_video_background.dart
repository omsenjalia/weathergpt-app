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
  var _showVideo = false;
  var _loadGeneration = 0;
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
    if (sky == SkyCondition.snow) return 'assets/videos/sky_fog.mp4';
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

    final generation = ++_loadGeneration;
    _activeKey = asset;
    final old = _controller;
    _controller = null;
    if (mounted) {
      setState(() {
        _ready = false;
        _showVideo = false;
      });
    }
    await old?.dispose();

    try {
      final c = VideoPlayerController.asset(asset);
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();

      // A newer weather/time update may have started another load while this
      // clip was initializing. Do not let a stale controller flash on screen.
      if (!mounted || generation != _loadGeneration) {
        await c.dispose();
        return;
      }

      setState(() {
        _controller = c;
        _ready = true;
      });
      // Let the fixed contrast veil settle before revealing a bright frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && generation == _loadGeneration) {
          setState(() => _showVideo = true);
        }
      });
    } catch (e) {
      debugPrint('Atmosphere video load failed: $asset → $e');
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _ready = false;
        _showVideo = false;
      });
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
    _loadGeneration++;
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
        // Bundled looping video. Fade it in so a bright first frame cannot
        // briefly wash out the copy during a weather/time-of-day transition.
        if (_ready && _controller != null && _controller!.value.isInitialized)
          AnimatedOpacity(
            opacity: _showVideo ? 0.72 : 0,
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOut,
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
        // Consistent contrast veil. Keep it above every clip so readability
        // does not change when the video or the time-of-day palette changes.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.30),
                Colors.black.withValues(alpha: 0.10),
                Colors.black.withValues(alpha: 0.22),
                Colors.black.withValues(alpha: 0.58),
              ],
              stops: const [0.0, 0.28, 0.62, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
