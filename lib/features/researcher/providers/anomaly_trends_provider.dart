import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chart_point.dart';

enum TrendMetric { temperature, rainfall }

class TrendNotifier extends StateNotifier<TrendMetric> {
  TrendNotifier({TrendMetric initial = TrendMetric.temperature})
      : super(initial);
  void select(TrendMetric metric) => state = metric;
}

final anomalyTrendsProvider =
    StateNotifierProvider<TrendNotifier, TrendMetric>((ref) => TrendNotifier());

const temperatureTrend = [
  ChartPoint(1996, 27.1),
  ChartPoint(2000, 27.3),
  ChartPoint(2004, 27.5),
  ChartPoint(2008, 27.7),
  ChartPoint(2012, 28.0),
  ChartPoint(2016, 28.2),
  ChartPoint(2020, 28.5),
  ChartPoint(2024, 28.7),
  ChartPoint(2026, 28.8),
];
const rainfallTrend = [
  ChartPoint(1996, 341),
  ChartPoint(2000, 326),
  ChartPoint(2004, 362),
  ChartPoint(2008, 331),
  ChartPoint(2012, 390),
  ChartPoint(2016, 348),
  ChartPoint(2020, 451),
  ChartPoint(2024, 387),
  ChartPoint(2026, 412),
];
