import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/outlined_button_pill.dart';
import '../providers/historical_data_provider.dart';
import '../widgets/chart_theme.dart';

class HistoricalDataScreen extends ConsumerWidget {
  const HistoricalDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historicalDataProvider);
    final points = historicalSeries[state.metric]!;
    final unit = state.metric == HistoricalMetric.rainfall
        ? 'mm'
        : state.metric == HistoricalMetric.temperature
            ? '°C'
            : '%';
    return Scaffold(
      appBar: AppBar(
          titleSpacing: 0, title: const _LocationTitle('Historical Weather')),
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
                            .setMetric(HistoricalMetric.values[i])),
                    const SizedBox(height: 16),
                    Row(children: [
                      const Expanded(child: Filter(label: '2000 - 2026')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Segmented(
                              labels: const ['Monthly', 'Yearly'],
                              selected: state.monthly ? 0 : 1,
                              compact: true,
                              onChanged: (i) => ref
                                  .read(historicalDataProvider.notifier)
                                  .setMonthly(i == 0)))
                    ]),
                    const SizedBox(height: 22),
                    SizedBox(
                        height: 230,
                        child: BarChart(BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            minY: 0,
                            maxY: state.metric == HistoricalMetric.rainfall
                                ? 700
                                : state.metric == HistoricalMetric.humidity
                                    ? 80
                                    : 32,
                            gridData: ResearchChartTheme.grid,
                            borderData: FlBorderData(show: false),
                            barTouchData: ResearchChartTheme.barTouch,
                            titlesData: _barTitles(points),
                            barGroups: points
                                .map((p) =>
                                    BarChartGroupData(x: p.x.toInt(), barRods: [
                                      BarChartRodData(
                                          toY: p.value,
                                          color: AppColors.researcherBlue,
                                          width: 8,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(3)))
                                    ]))
                                .toList()))),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: _Stat(
                              'Total ${state.metric.name[0].toUpperCase()}${state.metric.name.substring(1)} (2026)',
                              '${points.last.value.toStringAsFixed(state.metric == HistoricalMetric.temperature ? 1 : 0)} $unit')),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _Stat(
                              'Long-term Avg',
                              state.metric == HistoricalMetric.rainfall
                                  ? '337 mm'
                                  : state.metric == HistoricalMetric.temperature
                                      ? '27.6 °C'
                                      : '61%')),
                      const SizedBox(width: 8),
                      const Expanded(
                          child: _Stat('Anomaly', '+22.3%',
                              accent: AppColors.statusRed,
                              caption: 'Above normal'))
                    ]),
                    const SizedBox(height: 24),
                    OutlinedButtonPill(
                        label: '↓  Export Data',
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content:
                                    Text('Export prepared (demo only).')))),
                  ]))),
    );
  }
}

FlTitlesData _barTitles(List<dynamic> points) => FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
        sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                style: ResearchChartTheme.axisStyle))),
    bottomTitles: AxisTitles(
        sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (v, _) {
              final found = points.where((p) => p.x.toInt() == v.toInt());
              return found.isEmpty || v.toInt() % 2 != 0
                  ? const SizedBox()
                  : Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Text(v.toInt().toString(),
                          style: ResearchChartTheme.axisStyle));
            })));

class _LocationTitle extends StatelessWidget {
  const _LocationTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const Text('⌖ Ahmedabad, Gujarat',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary))
          ]);
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
      ]));
}

class Segmented extends StatelessWidget {
  const Segmented(
      {super.key,
      required this.labels,
      required this.selected,
      required this.onChanged,
      this.compact = false});
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
            border: Border.all(color: AppColors.borderSubtle)),
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
                              borderRadius: BorderRadius.circular(9)),
                          child: Text(labels[i],
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selected == i
                                      ? AppColors.ctaTextDark
                                      : AppColors.textSecondary))),
                    )))),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.accent, this.caption});
  final String label;
  final String value;
  final Color? accent;
  final String? caption;
  @override
  Widget build(BuildContext context) => AppCard(
      padding: const EdgeInsets.all(11),
      radius: 12,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: accent ?? AppColors.textPrimary)),
        if (caption != null)
          Text(caption!,
              style:
                  const TextStyle(fontSize: 9, color: AppColors.textSecondary))
      ]));
}
