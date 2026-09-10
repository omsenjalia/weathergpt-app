import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../providers/map_provider.dart';

// Design is inferred from the Windy-map requirement; no dedicated map mockup exists.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _mapController = MapController();
  static const _fallbackCenter = LatLng(23.0225, 72.5714);

  Color get _accent =>
      switch (Hive.box('settings').get('user_persona', defaultValue: 'everyone')
          as String) {
        'farmer' => AppColors.farmerGreen,
        'researcher' => AppColors.researcherBlue,
        _ => AppColors.statusAmber,
      };

  Future<void> _locate() async {
    final location =
        await ref.read(mapProvider.notifier).detectCurrentLocation();
    if (!mounted) return;
    if (location != null) {
      _mapController.move(location, 12);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Enable location permission and services to center the map.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = ref.watch(mapProvider);
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
                initialCenter: _fallbackCenter, initialZoom: 6),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.weathergpt.weathergpt_mobile',
              ),
              TileLayer(
                urlTemplate:
                    'https://tiles.windy.com/tiles/v10.0/${map.activeLayer.name}/{z}/{x}/{y}.png',
                tileBuilder: (_, tile, __) =>
                    Opacity(opacity: .62, child: tile),
                userAgentPackageName: 'com.weathergpt.weathergpt_mobile',
              ),
              if (map.currentLocation != null)
                MarkerLayer(markers: [
                  Marker(
                    point: map.currentLocation!,
                    width: 34,
                    height: 34,
                    child: _PulsingLocationDot(color: _accent),
                  ),
                ]),
            ],
          ),
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: AppCard(
                radius: 18,
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search, color: AppColors.textSecondary),
                    hintText: 'Search location',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 100,
            child: AppCard(
              padding: const EdgeInsets.all(8),
              radius: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: MapLayer.values
                    .map((layer) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _LayerChip(
                            label: switch (layer) {
                              MapLayer.wind => 'Wind',
                              MapLayer.rain => 'Rain',
                              MapLayer.temp => 'Temp',
                              MapLayer.pressure => 'Pressure',
                            },
                            selected: map.activeLayer == layer,
                            accent: _accent,
                            onTap: () =>
                                ref.read(mapProvider.notifier).setLayer(layer),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 22,
            child: AppCard(
              padding: const EdgeInsets.all(4),
              radius: 16,
              child: Column(children: [
                IconButton(
                  tooltip: 'Zoom in',
                  onPressed: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1),
                  icon: const Icon(Icons.add),
                ),
                const Divider(height: 1, color: AppColors.borderSubtle),
                IconButton(
                  tooltip: 'Zoom out',
                  onPressed: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1),
                  icon: const Icon(Icons.remove),
                ),
                const Divider(height: 1, color: AppColors.borderSubtle),
                IconButton(
                  tooltip: 'My location',
                  onPressed: map.isLoadingLocation ? null : _locate,
                  icon: map.isLoadingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.my_location, color: _accent),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  const _LayerChip(
      {required this.label,
      required this.selected,
      required this.accent,
      required this.onTap});
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? accent.withValues(alpha: .18) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: selected ? accent : AppColors.borderSubtle),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: selected ? accent : AppColors.textSecondary)),
          ),
        ),
      );
}

class _PulsingLocationDot extends StatefulWidget {
  const _PulsingLocationDot({required this.color});
  final Color color;

  @override
  State<_PulsingLocationDot> createState() => _PulsingLocationDotState();
}

class _PulsingLocationDotState extends State<_PulsingLocationDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: Tween<double>(begin: .8, end: 1.25).animate(_controller),
        child: Center(
            child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                    color: widget.color.withValues(alpha: .7), blurRadius: 10)
              ]),
        )),
      );
}
