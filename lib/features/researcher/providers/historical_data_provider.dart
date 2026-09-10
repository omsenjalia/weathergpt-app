import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chart_point.dart';

enum HistoricalMetric { rainfall, temperature, humidity }

class HistoricalDataState {
  const HistoricalDataState(
      {this.metric = HistoricalMetric.rainfall, this.monthly = true});
  final HistoricalMetric metric;
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

const historicalSeries = <HistoricalMetric, List<ChartPoint>>{
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
