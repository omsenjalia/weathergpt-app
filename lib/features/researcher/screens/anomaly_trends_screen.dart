import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/outlined_button_pill.dart';
import '../providers/anomaly_trends_provider.dart';
import '../widgets/chart_theme.dart';
import 'historical_data_screen.dart' show Filter, Segmented;

class AnomalyTrendsScreen extends ConsumerWidget {
  const AnomalyTrendsScreen({super.key, this.initialMetric});
  final TrendMetric? initialMetric;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metric = ref.watch(anomalyTrendsProvider);
    final points =
        metric == TrendMetric.temperature ? temperatureTrend : rainfallTrend;
    final warming = metric == TrendMetric.temperature;
    return Scaffold(
        appBar: AppBar(
            titleSpacing: 0,
            title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Anomaly & Trends',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  Text('⌖ Ahmedabad, Gujarat',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary))
                ])),
        body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Segmented(
                          labels: const ['Temperature', 'Rainfall'],
                          selected: metric.index,
                          onChanged: (i) => ref
                              .read(anomalyTrendsProvider.notifier)
                              .select(TrendMetric.values[i])),
                      const SizedBox(height: 16),
                      const Row(children: [
                        Expanded(child: Filter(label: 'Annual Average')),
                        SizedBox(width: 10),
                        Expanded(child: Filter(label: '1996 - 2026'))
                      ]),
                      const SizedBox(height: 20),
                      Text(
                          warming
                              ? 'Temperature trend (1996 - 2026)'
                              : 'Rainfall trend (1996 - 2026)',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      SizedBox(
                          height: 220,
                          child: LineChart(LineChartData(
                              minX: 1996,
                              maxX: 2026,
                              minY: warming ? 26 : 250,
                              maxY: warming ? 30 : 500,
                              gridData: ResearchChartTheme.grid,
                              borderData: FlBorderData(show: false),
                              lineTouchData: ResearchChartTheme.lineTouch,
                              titlesData: _lineTitles,
                              lineBarsData: [
                                LineChartBarData(
                                    spots: points
                                        .map((p) => FlSpot(p.x, p.value))
                                        .toList(),
                                    isCurved: true,
                                    color: warming
                                        ? AppColors.statusRed
                                        : AppColors.researcherBlue,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                        show: true,
                                        color: (warming
                                                ? AppColors.statusRed
                                                : AppColors.researcherBlue)
                                            .withValues(alpha: .08)))
                              ]))),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                            child: _Callout(
                                'Trend',
                                warming ? '+1.7°C' : '+22.3%',
                                warming ? 'over 30 years' : 'above normal',
                                warming
                                    ? AppColors.statusRed
                                    : AppColors.researcherBlue)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _Callout(
                                '2026 Average',
                                warming ? '28.8°C' : '412 mm',
                                warming ? '(+1.7°C)' : '(+22.3%)',
                                warming
                                    ? AppColors.statusRed
                                    : AppColors.researcherBlue))
                      ]),
                      const SizedBox(height: 14),
                      Text(
                          warming
                              ? 'Ahmedabad has become warmer over the last 30 years.'
                              : 'Ahmedabad rainfall is above its long-term average.',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 24),
                      Row(children: [
                        const Expanded(
                            child: OutlinedButtonPill(label: 'View Details')),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButtonPill(
                            label: '↓ Export Data',
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Export prepared (demo only).')),
                            ),
                          ),
                        )
                      ]),
                    ]))));
  }
}

final _lineTitles = FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
        sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                style: ResearchChartTheme.axisStyle))),
    bottomTitles: AxisTitles(
        sideTitles: SideTitles(
            showTitles: true,
            interval: 5,
            getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(v.toInt().toString(),
                    style: ResearchChartTheme.axisStyle)))));

class _Callout extends StatelessWidget {
  const _Callout(this.label, this.value, this.caption, this.color);
  final String label, value, caption;
  final Color color;
  @override
  Widget build(BuildContext context) => AppCard(
      padding: const EdgeInsets.all(14),
      radius: 12,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 7),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.w700)),
        Text(caption,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textSecondary))
      ]));
}
