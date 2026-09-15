import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/atmosphere_theme.dart';

/// Looping free stock weather footage (Mixkit / Coverr-style public CDN).
/// Falls back to a soft gradient if the stream fails.
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
  var _failed = false;
  String? _activeUrl;

  static String _urlFor(SkyPeriod period, SkyCondition sky) {
    // Prefer condition, then time-of-day. All URLs are free stock (Mixkit).
    if (sky == SkyCondition.thunder) {
      return 'https://assets.mixkit.co/videos/preview/mixkit-lightning-strikes-during-a-thunderstorm-39766-large.mp4';
    }
    if (sky == SkyCondition.heavyRain ||
        sky == SkyCondition.rain ||
        sky == SkyCondition.drizzle) {
      return 'https://assets.mixkit.co/videos/preview/mixkit-rain-falling-on-the-water-1262-large.mp4';
    }
    if (sky == SkyCondition.snow) {
      return 'https://assets.mixkit.co/videos/preview/mixkit-snow-falling-in-the-forest-1933-large.mp4';
    }
    if (sky == SkyCondition.fog) {
      return 'https://assets.mixkit.co/videos/preview/mixkit-fog-covering-a-forest-in-the-morning-42445-large.mp4';
    }
    if (sky == SkyCondition.overcast ||
        sky == SkyCondition.cloudy ||
        sky == SkyCondition.partlyCloudy) {
      return 'https://assets.mixkit.co/videos/preview/mixkit-clouds-moving-in-the-sky-2406-large.mp4';
    }
    switch (period) {
      case SkyPeriod.sunrise:
      case SkyPeriod.predawn:
        return 'https://assets.mixkit.co/videos/preview/mixkit-sunrise-over-the-sea-1628-large.mp4';
      case SkyPeriod.sunset:
      case SkyPeriod.goldenHour:
      case SkyPeriod.dusk:
        return 'https://assets.mixkit.co/videos/preview/mixkit-sunset-over-the-sea-1186-large.mp4';
      case SkyPeriod.night:
      case SkyPeriod.midnight:
      case SkyPeriod.evening:
        return 'https://assets.mixkit.co/videos/preview/mixkit-stars-in-space-1610-large.mp4';
      case SkyPeriod.midday:
      case SkyPeriod.morning:
      case SkyPeriod.afternoon:
        return 'https://assets.mixkit.co/videos/preview/mixkit-white-clouds-on-blue-sky-2407-large.mp4';
    }
  }

  Future<void> _load(String url) async {
    if (_activeUrl == url && (_ready || _failed)) return;
    _activeUrl = url;
    await _controller?.dispose();
    _controller = null;
    if (mounted) {
      setState(() {
        _ready = false;
        _failed = false;
      });
    }
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = c;
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _ready = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load(_urlFor(widget.period, widget.sky));
  }

  @override
  void didUpdateWidget(covariant AtmosphereVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period || oldWidget.sky != widget.sky) {
      _load(_urlFor(widget.period, widget.sky));
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
        // Always-present gradient underlay
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [p.top, p.mid, p.bottom],
            ),
          ),
        ),
        if (_ready && _controller != null)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        // Darken slightly so white text stays readable on bright footage
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.25),
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
