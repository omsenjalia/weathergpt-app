import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/outlined_button_pill.dart';
import '../providers/comparison_provider.dart';
import '../widgets/chart_theme.dart';
import 'historical_data_screen.dart' show Filter;

class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('Compare Locations',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Filter(label: 'Monsoon (Jun-Sep)'),
              const SizedBox(height: 16),
              Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: comparedLocations.map(_Legend.new).toList()),
              const SizedBox(height: 16),
              SizedBox(height: 230, child: BarChart(_chartData())),
              const SizedBox(height: 16),
              const Text('Total Rainfall (mm)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _Table(),
              const SizedBox(height: 24),
              const OutlinedButtonPill(label: 'View Detailed Analysis  →'),
            ]),
          ),
        ),
      );

  BarChartData _chartData() => BarChartData(
        maxY: 650,
        gridData: ResearchChartTheme.grid,
        borderData: FlBorderData(show: false),
        barTouchData: ResearchChartTheme.barTouch,
        titlesData: _titles,
        barGroups: List.generate(
            5,
            (year) => BarChartGroupData(
                  x: 2021 + year,
                  barsSpace: 3,
                  barRods: List.generate(
                      comparedLocations.length,
                      (i) => BarChartRodData(
                          toY: comparedLocations[i].points[year].value,
                          color: Color(comparedLocations[i].colorValue),
                          width: 7,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2)))),
                )),
      );
}

class _Legend extends StatelessWidget {
  const _Legend(this.location);
  final ComparedLocation location;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: Color(location.colorValue), shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(location.name,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary))
      ]);
}

final _titles = FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
        sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                style: ResearchChartTheme.axisStyle))),
    bottomTitles: AxisTitles(
        sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(v.toInt().toString(),
                    style: ResearchChartTheme.axisStyle)))));

class _Table extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      radius: 12,
      child: Table(children: [
        const TableRow(children: [
          Padding(
              padding: EdgeInsets.all(5),
              child: Text('Location',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 11))),
          Padding(
              padding: EdgeInsets.all(5),
              child: Text('2024',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 11))),
          Padding(
              padding: EdgeInsets.all(5),
              child: Text('2025',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 11)))
        ]),
        ...comparedLocations.map((l) => TableRow(children: [
              Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(l.name, style: const TextStyle(fontSize: 12))),
              Padding(
                  padding: const EdgeInsets.all(5),
                  child:
                      Text('${l.y2024}', style: const TextStyle(fontSize: 12))),
              Padding(
                  padding: const EdgeInsets.all(5),
                  child:
                      Text('${l.y2025}', style: const TextStyle(fontSize: 12)))
            ]))
      ]));
}
