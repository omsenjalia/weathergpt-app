import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chart_point.dart';

enum HistoricalMetric { rainfall, temperature, humidity }

class HistoricalDataState {
  const HistoricalDataState(
      {this.metric = HistoricalMetric.rainfall, this.monthly = false});
  final HistoricalMetric metric;
  /// When true, show month-of-year climatology; when false, yearly series.
  final bool monthly;

  HistoricalDataState copyWith({HistoricalMetric? metric, bool? monthly}) =>
      HistoricalDataState(
        metric: metric ?? this.metric,
        monthly: monthly ?? this.monthly,
      );
}

class HistoricalDataNotifier extends StateNotifier<HistoricalDataState> {
  HistoricalDataNotifier() : super(const HistoricalDataState());
  void setMetric(HistoricalMetric value) =>
      state = state.copyWith(metric: value);
  void setMonthly(bool value) => state = state.copyWith(monthly: value);
}

final historicalDataProvider =
    StateNotifierProvider<HistoricalDataNotifier, HistoricalDataState>(
  (ref) => HistoricalDataNotifier(),
);

/// Yearly series (x = year).
const yearlySeries = <HistoricalMetric, List<ChartPoint>>{
  HistoricalMetric.rainfall: [
    ChartPoint(2000, 208),
    ChartPoint(2003, 280),
    ChartPoint(2006, 191),
    ChartPoint(2009, 367),
    ChartPoint(2012, 294),
    ChartPoint(2015, 401),
    ChartPoint(2018, 355),
    ChartPoint(2020, 487),
    ChartPoint(2022, 569),
    ChartPoint(2024, 387),
    ChartPoint(2026, 412),
  ],
  HistoricalMetric.temperature: [
    ChartPoint(2000, 26.1),
    ChartPoint(2003, 26.4),
    ChartPoint(2006, 26.6),
    ChartPoint(2009, 27.0),
    ChartPoint(2012, 27.3),
    ChartPoint(2015, 27.5),
    ChartPoint(2018, 27.9),
    ChartPoint(2020, 28.1),
    ChartPoint(2022, 28.4),
    ChartPoint(2024, 28.6),
    ChartPoint(2026, 28.8),
  ],
  HistoricalMetric.humidity: [
    ChartPoint(2000, 58),
    ChartPoint(2003, 60),
    ChartPoint(2006, 57),
    ChartPoint(2009, 62),
    ChartPoint(2012, 61),
    ChartPoint(2015, 63),
    ChartPoint(2018, 60),
    ChartPoint(2020, 64),
    ChartPoint(2022, 66),
    ChartPoint(2024, 63),
    ChartPoint(2026, 65),
  ],
};

/// Monthly climatology (x = month 1–12).
const monthlySeries = <HistoricalMetric, List<ChartPoint>>{
  HistoricalMetric.rainfall: [
    ChartPoint(1, 2),
    ChartPoint(2, 1),
    ChartPoint(3, 3),
    ChartPoint(4, 8),
    ChartPoint(5, 18),
    ChartPoint(6, 95),
    ChartPoint(7, 210),
    ChartPoint(8, 185),
    ChartPoint(9, 110),
    ChartPoint(10, 25),
    ChartPoint(11, 6),
    ChartPoint(12, 2),
  ],
  HistoricalMetric.temperature: [
    ChartPoint(1, 20.5),
    ChartPoint(2, 23.1),
    ChartPoint(3, 27.8),
    ChartPoint(4, 31.5),
    ChartPoint(5, 33.2),
    ChartPoint(6, 31.0),
    ChartPoint(7, 28.4),
    ChartPoint(8, 27.9),
    ChartPoint(9, 28.6),
    ChartPoint(10, 28.1),
    ChartPoint(11, 24.8),
    ChartPoint(12, 21.2),
  ],
  HistoricalMetric.humidity: [
    ChartPoint(1, 42),
    ChartPoint(2, 38),
    ChartPoint(3, 35),
    ChartPoint(4, 40),
    ChartPoint(5, 48),
    ChartPoint(6, 68),
    ChartPoint(7, 78),
    ChartPoint(8, 80),
    ChartPoint(9, 74),
    ChartPoint(10, 55),
    ChartPoint(11, 48),
    ChartPoint(12, 45),
  ],
};

List<ChartPoint> seriesFor(HistoricalDataState state) =>
    state.monthly ? monthlySeries[state.metric]! : yearlySeries[state.metric]!;

double longTermAverage(List<ChartPoint> points) {
  if (points.isEmpty) return 0;
  return points.map((p) => p.value).reduce((a, b) => a + b) / points.length;
}

/// Percent anomaly of the latest point vs long-term average.
double anomalyPercent(List<ChartPoint> points) {
  final avg = longTermAverage(points);
  if (avg == 0 || points.isEmpty) return 0;
  return ((points.last.value - avg) / avg) * 100;
}

String metricLabel(HistoricalMetric m) => switch (m) {
      HistoricalMetric.rainfall => 'Rainfall',
      HistoricalMetric.temperature => 'Temperature',
      HistoricalMetric.humidity => 'Humidity',
    };

String metricUnit(HistoricalMetric m) => switch (m) {
      HistoricalMetric.rainfall => 'mm',
      HistoricalMetric.temperature => '°C',
      HistoricalMetric.humidity => '%',
    };
