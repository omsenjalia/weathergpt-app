import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/outlined_button_pill.dart';
import '../../home/providers/location_provider.dart';
import '../providers/historical_data_provider.dart';
import '../widgets/chart_theme.dart';

class HistoricalDataScreen extends ConsumerWidget {
  const HistoricalDataScreen({super.key});

  static const _months = [
    'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historicalDataProvider);
    final location = ref.watch(locationProvider);
    final points = seriesFor(state);
    final unit = metricUnit(state.metric);
    final avg = longTermAverage(points);
    final anomaly = anomalyPercent(points);
    final latest = points.isEmpty ? 0.0 : points.last.value;
    final maxY = points.isEmpty
        ? 10.0
        : (points.map((p) => p.value).reduce((a, b) => a > b ? a : b) * 1.15)
            .clamp(1.0, 10000.0);

    final latestLabel = state.monthly
        ? 'Latest month'
        : 'Latest (${points.isEmpty ? '—' : points.last.x.toInt()})';
    final valueLabel = state.metric == HistoricalMetric.humidity
        ? 'Avg ${metricLabel(state.metric)}'
        : state.metric == HistoricalMetric.temperature
            ? 'Avg ${metricLabel(state.metric)}'
            : 'Total ${metricLabel(state.metric)}';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Historical Weather',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(
              location.name,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Segmented(
                labels: const ['Rainfall', 'Temperature', 'Humidity'],
                selected: state.metric.index,
                onChanged: (i) => ref
                    .read(historicalDataProvider.notifier)
                    .setMetric(HistoricalMetric.values[i]),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Filter(label: '2000 – 2026')),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Segmented(
                      labels: const ['Monthly', 'Yearly'],
                      selected: state.monthly ? 0 : 1,
                      compact: true,
                      onChanged: (i) => ref
                          .read(historicalDataProvider.notifier)
                          .setMonthly(i == 0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 240,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    minY: 0,
                    maxY: maxY,
                    gridData: ResearchChartTheme.grid,
                    borderData: FlBorderData(show: false),
                    barTouchData: ResearchChartTheme.barTouch,
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          interval: maxY / 4,
                          getTitlesWidget: (v, _) => Text(
                            v >= 100 ? v.toInt().toString() : v.toStringAsFixed(0),
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textTertiary),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (state.monthly) {
                              if (i < 1 || i > 12) return const SizedBox.shrink();
                              // Show every other month to avoid crush
                              if (i % 2 == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(_months[i - 1],
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textTertiary)),
                                );
                              }
                              return const SizedBox.shrink();
                            }
                            // Yearly: only label every 2nd point
                            final years = points.map((p) => p.x.toInt()).toList();
                            if (!years.contains(i)) return const SizedBox.shrink();
                            final idx = years.indexOf(i);
                            if (idx % 2 != 0 && idx != years.length - 1) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('$i',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textTertiary)),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: points
                        .map(
                          (p) => BarChartGroupData(
                            x: p.x.toInt(),
                            barRods: [
                              BarChartRodData(
                                toY: p.value,
                                color: AppColors.researcherBlue,
                                width: state.monthly ? 12 : 10,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3)),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      '$valueLabel\n($latestLabel)',
                      '${latest.toStringAsFixed(state.metric == HistoricalMetric.temperature ? 1 : 0)} $unit',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Stat(
                      'Long-term\nAvg',
                      '${avg.toStringAsFixed(state.metric == HistoricalMetric.temperature ? 1 : 0)} $unit',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Stat(
                      'Anomaly',
                      '${anomaly >= 0 ? '+' : ''}${anomaly.toStringAsFixed(1)}%',
                      valueColor: anomaly.abs() < 5
                          ? AppColors.textPrimary
                          : anomaly > 0
                              ? AppColors.statusRed
                              : AppColors.statusGreenText,
                      subtitle: anomaly.abs() < 5
                          ? 'Near normal'
                          : anomaly > 0
                              ? 'Above normal'
                              : 'Below normal',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButtonPill(
                label: '↓  Export Data',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export coming soon (CSV).'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.valueColor, this.subtitle});
  final String label;
  final String value;
  final Color? valueColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary, height: 1.25)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textTertiary)),
          ],
        ],
      ),
    );
  }
}

class Filter extends StatelessWidget {
  const Filter({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        radius: 10,
        child: Row(children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const Spacer(),
          const Icon(Icons.keyboard_arrow_down, size: 17)
        ]),
      );
}

class Segmented extends StatelessWidget {
  const Segmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        height: compact ? 42 : 44,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: List.generate(
            labels.length,
            (i) => Expanded(
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == i
                        ? AppColors.ctaWhite
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected == i
                          ? AppColors.ctaTextDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
