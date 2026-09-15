import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_colors.dart';

/// Maps a free-text weather condition to a short looping asset video.
String weatherVideoAssetFor(String condition) {
  final s = condition.toLowerCase();
  if (s.contains('thunder') || s.contains('storm') || s.contains('lightning')) {
    return 'assets/videos/storm.mp4';
  }
  if (s.contains('rain') ||
      s.contains('drizzle') ||
      s.contains('shower') ||
      s.contains('precip')) {
    return 'assets/videos/rain.mp4';
  }
  if (s.contains('clear') ||
      s.contains('sun') ||
      s.contains('fair') ||
      s.contains('hot')) {
    return 'assets/videos/clear.mp4';
  }
  // cloudy / overcast / fog / mist / default
  return 'assets/videos/cloudy.mp4';
}

class WeatherVideoBackground extends StatefulWidget {
  const WeatherVideoBackground({
    super.key,
    required this.condition,
    this.opacity = 0.45,
  });

  final String condition;
  final double opacity;

  @override
  State<WeatherVideoBackground> createState() => _WeatherVideoBackgroundState();
}

class _WeatherVideoBackgroundState extends State<WeatherVideoBackground> {
  VideoPlayerController? _controller;
  String? _loadedAsset;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _load(widget.condition);
  }

  @override
  void didUpdateWidget(covariant WeatherVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.condition != widget.condition) {
      _load(widget.condition);
    }
  }

  Future<void> _load(String condition) async {
    final asset = weatherVideoAssetFor(condition);
    if (asset == _loadedAsset && _controller != null) return;

    final previous = _controller;
    _controller = null;
    _ready = false;
    if (mounted) setState(() {});

    try {
      final c = VideoPlayerController.asset(asset);
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _loadedAsset = asset;
        _ready = true;
      });
    } catch (_) {
      // Silent fallback — gradient still shows
      if (mounted) setState(() => _ready = false);
    } finally {
      await previous?.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base gradient always present
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.gradientHero),
        ),
        if (_ready && _controller != null)
          Opacity(
            opacity: widget.opacity,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
        // Darken so UI text stays readable
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.bgPrimary.withValues(alpha: 0.35),
                AppColors.bgPrimary.withValues(alpha: 0.75),
                AppColors.bgPrimary,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
