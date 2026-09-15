import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_colors.dart';

/// All Open-Meteo / WMO weather codes used by the backend → asset path.
/// 22 named situations covering the full code table.
String weatherVideoAssetForCode(int code) {
  switch (code) {
    case 0:
      return 'assets/videos/clear.mp4';
    case 1:
      return 'assets/videos/mainly_clear.mp4';
    case 2:
      return 'assets/videos/partly_cloudy.mp4';
    case 3:
      return 'assets/videos/overcast.mp4';
    case 45:
      return 'assets/videos/fog.mp4';
    case 48:
      return 'assets/videos/rime_fog.mp4';
    case 51:
      return 'assets/videos/light_drizzle.mp4';
    case 53:
      return 'assets/videos/drizzle.mp4';
    case 55:
      return 'assets/videos/heavy_drizzle.mp4';
    case 56:
    case 57:
      return 'assets/videos/freezing_rain.mp4';
    case 61:
      return 'assets/videos/light_rain.mp4';
    case 63:
      return 'assets/videos/rain.mp4';
    case 65:
      return 'assets/videos/heavy_rain.mp4';
    case 66:
    case 67:
      return 'assets/videos/freezing_rain.mp4';
    case 71:
      return 'assets/videos/light_snow.mp4';
    case 73:
      return 'assets/videos/snow.mp4';
    case 75:
      return 'assets/videos/heavy_snow.mp4';
    case 77:
      return 'assets/videos/snow_grains.mp4';
    case 80:
      return 'assets/videos/rain_shower.mp4';
    case 81:
      return 'assets/videos/rain_shower.mp4';
    case 82:
      return 'assets/videos/heavy_shower.mp4';
    case 85:
      return 'assets/videos/snow_shower.mp4';
    case 86:
      return 'assets/videos/snow_shower.mp4';
    case 95:
      return 'assets/videos/thunderstorm.mp4';
    case 96:
    case 99:
      return 'assets/videos/thunderstorm_hail.mp4';
    default:
      return 'assets/videos/overcast.mp4';
  }
}

/// Fallback when only condition text is available.
String weatherVideoAssetForCondition(String condition) {
  final s = condition.toLowerCase();
  if (s.contains('thunder') || s.contains('storm') || s.contains('lightning')) {
    return s.contains('hail')
        ? 'assets/videos/thunderstorm_hail.mp4'
        : 'assets/videos/thunderstorm.mp4';
  }
  if (s.contains('snow') || s.contains('sleet') || s.contains('blizzard')) {
    if (s.contains('heavy')) return 'assets/videos/heavy_snow.mp4';
    if (s.contains('light') || s.contains('slight')) {
      return 'assets/videos/light_snow.mp4';
    }
    if (s.contains('shower')) return 'assets/videos/snow_shower.mp4';
    if (s.contains('grain')) return 'assets/videos/snow_grains.mp4';
    return 'assets/videos/snow.mp4';
  }
  if (s.contains('freezing')) return 'assets/videos/freezing_rain.mp4';
  if (s.contains('drizzle')) {
    if (s.contains('heavy') || s.contains('dense')) {
      return 'assets/videos/heavy_drizzle.mp4';
    }
    if (s.contains('light')) return 'assets/videos/light_drizzle.mp4';
    return 'assets/videos/drizzle.mp4';
  }
  if (s.contains('rain') || s.contains('shower') || s.contains('precip')) {
    if (s.contains('violent') || s.contains('heavy')) {
      return 'assets/videos/heavy_rain.mp4';
    }
    if (s.contains('shower')) return 'assets/videos/rain_shower.mp4';
    if (s.contains('light') || s.contains('slight')) {
      return 'assets/videos/light_rain.mp4';
    }
    return 'assets/videos/rain.mp4';
  }
  if (s.contains('fog') || s.contains('mist') || s.contains('haze')) {
    return s.contains('rime') || s.contains('freezing')
        ? 'assets/videos/rime_fog.mp4'
        : 'assets/videos/fog.mp4';
  }
  if (s.contains('overcast') || s.contains('cloud')) {
    if (s.contains('partly')) return 'assets/videos/partly_cloudy.mp4';
    if (s.contains('mainly') || s.contains('mostly')) {
      return 'assets/videos/mainly_clear.mp4';
    }
    return 'assets/videos/overcast.mp4';
  }
  if (s.contains('clear') || s.contains('sun') || s.contains('fair')) {
    return 'assets/videos/clear.mp4';
  }
  return 'assets/videos/overcast.mp4';
}

class WeatherVideoBackground extends StatefulWidget {
  const WeatherVideoBackground({
    super.key,
    required this.condition,
    this.weatherCode,
    this.opacity = 0.5,
  });

  final String condition;
  final int? weatherCode;
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
    _load();
  }

  @override
  void didUpdateWidget(covariant WeatherVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.condition != widget.condition ||
        oldWidget.weatherCode != widget.weatherCode) {
      _load();
    }
  }

  String get _asset {
    final code = widget.weatherCode;
    if (code != null && code > 0) return weatherVideoAssetForCode(code);
    return weatherVideoAssetForCondition(widget.condition);
  }

  Future<void> _load() async {
    final asset = _asset;
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
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.bgPrimary.withValues(alpha: 0.3),
                AppColors.bgPrimary.withValues(alpha: 0.7),
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
