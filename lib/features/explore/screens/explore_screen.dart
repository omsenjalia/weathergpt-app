import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../home/providers/location_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/map_provider.dart';

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
    MapLayer.wind: (Icons.air, Color(0xFF38BDF8), 'map.layer_wind'),
    MapLayer.rain: (Icons.water_drop_outlined, Color(0xFF60A5FA), 'map.layer_rain'),
    MapLayer.temp: (Icons.thermostat, Color(0xFFF59E0B), 'map.layer_temp'),
    MapLayer.clouds: (Icons.cloud_outlined, Color(0xFF94A3B8), 'map.layer_clouds'),
    MapLayer.radar: (Icons.radar, Color(0xFF10B981), 'map.layer_radar'),
    MapLayer.waves: (Icons.waves, Color(0xFF06B6D4), 'map.layer_waves'),
    MapLayer.pressure: (Icons.speed, Color(0xFFEC4899), 'map.layer_pressure'),
    MapLayer.thunder: (Icons.thunderstorm_outlined, Color(0xFFA78BFA), 'map.layer_thunder'),
    MapLayer.snow: (Icons.ac_unit, Color(0xFFE0F2FE), 'map.layer_snow'),
    MapLayer.humidity: (Icons.opacity, Color(0xFF34D399), 'map.layer_humidity'),
    MapLayer.cape: (Icons.bolt, Color(0xFFF97316), 'map.layer_cape'),
  };

  static const _productLabels = <MapProduct, String>{
    MapProduct.ecmwf: 'ECMWF',
    MapProduct.gfs: 'GFS',
    MapProduct.icon: 'ICON',
    MapProduct.nems: 'NEMS',
  };

  Color get _accent {
    final persona = ref.watch(settingsProvider).userPersona;
    return switch (persona) {
      'farmer' => AppColors.farmerGreen,
      'researcher' => AppColors.researcherBlue,
      _ => AppColors.accent,
    };
  }

  String _embedUrl(MapState map) {
    final overlay = map.activeLayer.name;
    final product = map.product.name;
    final menu = map.showMenu ? 'true' : '';
    final marker = map.showMarker ? 'true' : '';
    return 'https://embed.windy.com/embed2.html'
        '?lat=${map.lat}&lon=${map.lon}'
        '&detailLat=${map.lat}&detailLon=${map.lon}'
        '&width=100%25&height=100%25'
        '&zoom=${map.zoom}'
        '&level=surface'
        '&overlay=$overlay'
        '&product=$product'
        '&menu=$menu'
        '&message=true'
        '&marker=$marker'
        '&calendar=now'
        '&pressure='
        '&type=map'
        '&location=coordinates'
        '&detail=true'
        '&metricWind=default'
        '&metricTemp=default'
        '&radarRange=-1';
  }

  void _ensureController(MapState map) {
    final url = _embedUrl(map);
    if (_controller == null) {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF0B1220))
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('map.location_denied'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = ref.watch(mapProvider);
    final homeLoc = ref.watch(locationProvider);
    final persona = ref.watch(settingsProvider).userPersona;
    final isResearcher = persona == 'researcher';

    if ((map.lat - homeLoc.lat).abs() > 0.01 ||
        (map.lon - homeLoc.lon).abs() > 0.01) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(mapProvider.notifier)
            .setCenter(homeLoc.lat, homeLoc.lon, zoom: map.zoom < 7 ? 8 : map.zoom);
      });
    }
    _ensureController(map);

    final layers = isResearcher
        ? _layerMeta.keys.toList()
        : [
            MapLayer.wind,
            MapLayer.rain,
            MapLayer.temp,
            MapLayer.clouds,
            MapLayer.radar,
            MapLayer.pressure,
          ];

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Row(
                children: [
                  Text(
                    'map.title'.tr(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (isResearcher)
                    Text(
                      'map.researcher_mode'.tr(),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.researcherBlue),
                    ),
                ],
              ),
            ),
            // Layer chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: layers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final layer = layers[i];
                  final meta = _layerMeta[layer]!;
                  final selected = map.activeLayer == layer;
                  return FilterChip(
                    selected: selected,
                    showCheckmark: false,
                    avatar: Icon(meta.$1,
                        size: 16,
                        color: selected ? Colors.white : meta.$2),
                    label: Text(meta.$3.tr()),
                    selectedColor: _accent.withValues(alpha: 0.35),
                    backgroundColor: AppColors.surfaceCard,
                    side: BorderSide(
                      color: selected
                          ? _accent.withValues(alpha: 0.7)
                          : AppColors.borderSubtle,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    onSelected: (_) =>
                        ref.read(mapProvider.notifier).setLayer(layer),
                  );
                },
              ),
            ),
            if (isResearcher) ...[
              const SizedBox(height: 6),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final p in MapProduct.values) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_productLabels[p]!),
                          selected: map.product == p,
                          onSelected: (_) =>
                              ref.read(mapProvider.notifier).setProduct(p),
                          selectedColor:
                              AppColors.researcherBlue.withValues(alpha: 0.3),
                          labelStyle: const TextStyle(fontSize: 11),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 6),
            Expanded(
              child: Stack(
                children: [
                  if (_controller != null)
                    WebViewWidget(controller: _controller!),
                  if (_loading)
                    const ColoredBox(
                      color: Color(0xFF0B1220),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  Positioned(
                    right: 12,
                    bottom: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MapFab(
                          icon: Icons.add,
                          color: _accent,
                          onTap: () =>
                              ref.read(mapProvider.notifier).zoomIn(),
                        ),
                        const SizedBox(height: 8),
                        _MapFab(
                          icon: Icons.remove,
                          color: _accent,
                          onTap: () =>
                              ref.read(mapProvider.notifier).zoomOut(),
                        ),
                        const SizedBox(height: 8),
                        _MapFab(
                          icon: map.isLoadingLocation
                              ? null
                              : Icons.my_location,
                          loading: map.isLoadingLocation,
                          color: _accent,
                          onTap: _locate,
                        ),
                        if (isResearcher) ...[
                          const SizedBox(height: 8),
                          _MapFab(
                            icon: map.showMenu
                                ? Icons.menu_open
                                : Icons.menu,
                            color: _accent,
                            onTap: () =>
                                ref.read(mapProvider.notifier).toggleMenu(),
                          ),
                          const SizedBox(height: 8),
                          _MapFab(
                            icon: map.showMarker
                                ? Icons.location_on
                                : Icons.location_off_outlined,
                            color: _accent,
                            onTap: () => ref
                                .read(mapProvider.notifier)
                                .toggleMarker(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(
                        'Windy · ${_productLabels[map.product]} · z${map.zoom}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

class _MapFab extends StatelessWidget {
  const _MapFab({
    required this.color,
    required this.onTap,
    this.icon,
    this.loading = false,
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
          width: 44,
          height: 44,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: color),
                  )
                : Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}
