import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../providers/map_provider.dart';
import '../../home/providers/location_provider.dart';

/// Explore map powered by Windy's official embed (same approach as the web app).
///
/// Uses [https://embed.windy.com/embed2.html] inside a [WebView], with in-app
/// layer chips that change the `overlay=` query parameter.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  WebViewController? _controller;
  var _loading = true;
  String? _lastUrl;

  static const _layerMeta = <MapLayer, (IconData, Color, String)>{
    MapLayer.wind: (Icons.air, Color(0xFF38BDF8), 'Wind'),
    MapLayer.rain: (Icons.water_drop_outlined, Color(0xFF60A5FA), 'Rain'),
    MapLayer.temp: (Icons.thermostat, Color(0xFFF59E0B), 'Temp'),
    MapLayer.clouds: (Icons.cloud_outlined, Color(0xFF94A3B8), 'Clouds'),
    MapLayer.radar: (Icons.radar, Color(0xFF10B981), 'Radar'),
    MapLayer.waves: (Icons.waves, Color(0xFF06B6D4), 'Waves'),
    MapLayer.pressure: (Icons.speed, Color(0xFFEC4899), 'Pressure'),
  };

  Color get _accent {
    final persona = Hive.box('settings')
        .get('user_persona', defaultValue: 'everyone') as String;
    return switch (persona) {
      'farmer' => AppColors.farmerGreen,
      'researcher' => AppColors.researcherBlue,
      _ => AppColors.statusAmber,
    };
  }

  String _embedUrl(MapState map) {
    final lat = map.lat;
    final lon = map.lon;
    final zoom = map.zoom;
    final overlay = map.activeLayer.name;
    return 'https://embed.windy.com/embed2.html'
        '?lat=$lat&lon=$lon'
        '&detailLat=$lat&detailLon=$lon'
        '&width=100%25&height=100%25'
        '&zoom=$zoom'
        '&level=surface'
        '&overlay=$overlay'
        '&product=ecmwf'
        '&menu='
        '&message=true'
        '&marker=true'
        '&calendar=now'
        '&pressure='
        '&type=map'
        '&location=coordinates'
        '&detail='
        '&metricWind=default'
        '&metricTemp=default'
        '&radarRange=-1';
  }

  void _ensureController(MapState map) {
    final url = _embedUrl(map);
    if (_controller == null) {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF0A0A0C))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _loading = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
            onWebResourceError: (_) {
              if (mounted) setState(() => _loading = false);
            },
          ),
        )
        ..loadRequest(Uri.parse(url));
      _controller = controller;
      _lastUrl = url;
      return;
    }
    if (_lastUrl != url) {
      _lastUrl = url;
      _controller!.loadRequest(Uri.parse(url));
    }
  }

  Future<void> _locate() async {
    final location =
        await ref.read(mapProvider.notifier).detectCurrentLocation();
    if (!mounted) return;
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Enable location permission and services to center the map.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = ref.watch(mapProvider);
    final homeLoc = ref.watch(locationProvider);
    // Keep Windy embed aligned with the location chosen on Home.
    if ((map.lat - homeLoc.lat).abs() > 0.01 ||
        (map.lon - homeLoc.lon).abs() > 0.01) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(mapProvider.notifier).setCenter(homeLoc.lat, homeLoc.lon, zoom: 8);
      });
    }
    _ensureController(map);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _LayerBar(
              active: map.activeLayer,
              accent: _accent,
              meta: _layerMeta,
              onSelect: (layer) =>
                  ref.read(mapProvider.notifier).setLayer(layer),
            ),
            Expanded(
              child: Stack(
                children: [
                  if (_controller != null)
                    WebViewWidget(controller: _controller!),
                  if (_loading)
                    const ColoredBox(
                      color: Color(0xFF0A0A0C),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  Positioned(
                    right: 16,
                    bottom: 24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MapFab(
                          icon: map.isLoadingLocation
                              ? null
                              : Icons.my_location,
                          loading: map.isLoadingLocation,
                          color: _accent,
                          onTap: _locate,
                        ),
                        const SizedBox(height: 10),
                        const AppCard(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          radius: 10,
                          child: Text(
                            'Windy · ECMWF',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerBar extends StatelessWidget {
  const _LayerBar({
    required this.active,
    required this.accent,
    required this.meta,
    required this.onSelect,
  });

  final MapLayer active;
  final Color accent;
  final Map<MapLayer, (IconData, Color, String)> meta;
  final ValueChanged<MapLayer> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final entry in meta.entries) ...[
              _LayerChip(
                label: entry.value.$3,
                icon: entry.value.$1,
                color: entry.value.$2,
                selected: active == entry.key,
                accent: accent,
                onTap: () => onSelect(entry.key),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  const _LayerChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.28) : AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? accent.withValues(alpha: 0.7) : AppColors.borderSubtle,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: selected ? Colors.white : color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  const _MapFab({
    required this.icon,
    required this.loading,
    required this.color,
    required this.onTap,
  });

  final IconData? icon;
  final bool loading;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: loading ? null : onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }
}
