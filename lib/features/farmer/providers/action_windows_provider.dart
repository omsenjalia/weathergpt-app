import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/api_client.dart';
import '../../home/providers/location_provider.dart';
import '../models/advisory_models.dart';
import 'farm_profile_provider.dart';

export '../models/advisory_models.dart';

enum AdvisoryStatus { loading, ready, fallback }

class ActionWindowsState {
  const ActionWindowsState({
    required this.selectedTab,
    required this.irrigationWindows,
    required this.sprayingWindows,
    required this.fieldWorkWindows,
    required this.fieldWorkStatus,
    required this.summaryVerdict,
    required this.summaryExplanation,
    this.status = AdvisoryStatus.ready,
    this.source = AdvisorySource.thresholds,
    this.aiConfidence,
    this.locationLabel = '',
  });

  final ActionWindowTab selectedTab;
  final List<HourlySuitability> irrigationWindows;
  final List<HourlySuitability> sprayingWindows;
  final List<HourlySuitability> fieldWorkWindows;
  final String fieldWorkStatus;
  final String summaryVerdict;
  final String summaryExplanation;
  final AdvisoryStatus status;
  final AdvisorySource source;
  final double? aiConfidence;
  final String locationLabel;

  /// True when a high-confidence System One answer actually shaped this state.
  bool get aiAssisted => source == AdvisorySource.systemOne;

  ActionWindowsState copyWith({
    AdvisoryStatus? status,
    AdvisorySource? source,
    double? aiConfidence,
    String? locationLabel,
  }) =>
      ActionWindowsState(
        selectedTab: selectedTab,
        irrigationWindows: irrigationWindows,
        sprayingWindows: sprayingWindows,
        fieldWorkWindows: fieldWorkWindows,
        fieldWorkStatus: fieldWorkStatus,
        summaryVerdict: summaryVerdict,
        summaryExplanation: summaryExplanation,
        status: status ?? this.status,
        source: source ?? this.source,
        aiConfidence: aiConfidence ?? this.aiConfidence,
        locationLabel: locationLabel ?? this.locationLabel,
      );
}

class ActionWindowsNotifier extends StateNotifier<ActionWindowsState> {
  ActionWindowsNotifier(this._ref)
      : super(_fallbackData[ActionWindowTab.today]!
            .copyWith(status: AdvisoryStatus.loading));

  final Ref _ref;
  final Map<ActionWindowTab, ActionWindowsState> _cache = {};
  bool _attempted = false;

  void selectTab(ActionWindowTab tab) {
    final cached = _cache[tab];
    if (cached != null) {
      state = cached;
      return;
    }
    // No data for this tab yet: show the bundled baseline while the first
    // fetch is in flight, or as the offline answer once it has failed.
    state = _fallbackData[tab]!.copyWith(
      status: _attempted ? AdvisoryStatus.fallback : AdvisoryStatus.loading,
      source: _attempted ? AdvisorySource.offline : null,
    );
    if (!_attempted) refresh();
  }

  Future<void> refresh() async {
    _attempted = true;
    final location = _ref.read(locationProvider);
    final crop = _ref.read(farmProfileProvider).crop;
    try {
      final data = await ApiClient.instance.get(ApiEndpoints.advisory, query: {
        'lat': location.lat,
        'lon': location.lon,
        'crop': crop,
        'days': 7,
      });
      final today = _stateForTab(ActionWindowTab.today, data, location.name);
      final tomorrow = _stateForTab(ActionWindowTab.tomorrow, data, location.name);
      final sevenDay = _stateForTab(ActionWindowTab.sevenDay, data, location.name);
      _cache
        ..[ActionWindowTab.today] = today
        ..[ActionWindowTab.tomorrow] = tomorrow
        ..[ActionWindowTab.sevenDay] = sevenDay;
      state = _cache[state.selectedTab] ?? today;
    } on AppApiError {
      _markUnavailable();
    } catch (_) {
      _markUnavailable();
    }
  }

  void _markUnavailable() {
    final tab = state.selectedTab;
    final fallback = _fallbackData[tab]!.copyWith(
      status: AdvisoryStatus.fallback,
      source: AdvisorySource.offline,
    );
    _cache[tab] = fallback;
    state = fallback;
  }

  static ActionWindowsState _stateForTab(
      ActionWindowTab tab, Map<String, dynamic> data, String locationLabel) {
    final windows = (data['windows'] as List?) ?? const [];
    final ai = data['ai'] is Map
        ? (data['ai'] as Map).cast<String, dynamic>()
        : null;
    final applied = aiApplied(ai);
    final source = applied ? AdvisorySource.systemOne : AdvisorySource.thresholds;
    final confidence = aiMeanConfidence(ai);
    final backendSummary = '${data['summary'] ?? ''}';

    Map<String, dynamic>? windowAt(int index) {
      if (index >= windows.length || windows[index] is! Map) return null;
      return (windows[index] as Map).cast<String, dynamic>();
    }

    List<HourlySuitability> hourlyOf(Map<String, dynamic>? window, String key) {
      final hourly = (window?['hourly'] as Map?) ?? const {};
      final cells = (hourly[key] as List?) ?? const [];
      return collapseHourlyCells(cells);
    }

    String bestWindowOf(Map<String, dynamic>? window) =>
        '${window?['best_window'] ?? 'Good Conditions'}';

    final today = windowAt(0);
    final tomorrow = windowAt(1) ?? today;

    switch (tab) {
      case ActionWindowTab.today:
        return ActionWindowsState(
          selectedTab: tab,
          irrigationWindows: hourlyOf(today, 'irrigation'),
          sprayingWindows: hourlyOf(today, 'spraying'),
          fieldWorkWindows: hourlyOf(today, 'field_work'),
          fieldWorkStatus: bestWindowOf(today),
          summaryVerdict: verdictTextForBand(
              aiOverallVerdict(ai) ?? today?['suitability'] as String?),
          summaryExplanation: '${today?['summary'] ?? backendSummary}',
          status: AdvisoryStatus.ready,
          source: source,
          aiConfidence: confidence,
          locationLabel: locationLabel,
        );
      case ActionWindowTab.tomorrow:
        return ActionWindowsState(
          selectedTab: tab,
          irrigationWindows: hourlyOf(tomorrow, 'irrigation'),
          sprayingWindows: hourlyOf(tomorrow, 'spraying'),
          fieldWorkWindows: hourlyOf(tomorrow, 'field_work'),
          fieldWorkStatus: bestWindowOf(tomorrow),
          summaryVerdict:
              verdictTextForBand(tomorrow?['suitability'] as String?),
          summaryExplanation: '${tomorrow?['summary'] ?? backendSummary}',
          status: AdvisoryStatus.ready,
          source: source,
          aiConfidence: confidence,
          locationLabel: locationLabel,
        );
      case ActionWindowTab.sevenDay:
        return ActionWindowsState(
          selectedTab: tab,
          irrigationWindows: dailySuitabilityCells(windows),
          sprayingWindows: dailySuitabilityCells(windows),
          fieldWorkWindows: dailySuitabilityCells(windows),
          fieldWorkStatus: 'Next 7 days',
          summaryVerdict: 'This week at a glance',
          summaryExplanation: backendSummary,
          status: AdvisoryStatus.ready,
          source: source,
          aiConfidence: confidence,
          locationLabel: locationLabel,
        );
    }
  }
}

/// Bundled baseline shown while loading and when the backend is unreachable.
const _avoid = HourlySuitability(Suitability.avoid);
const _neutral = HourlySuitability(Suitability.neutral);
const _good = HourlySuitability(Suitability.good);
const _caution = HourlySuitability(Suitability.caution);

final _fallbackData = <ActionWindowTab, ActionWindowsState>{
  ActionWindowTab.today: const ActionWindowsState(
    selectedTab: ActionWindowTab.today,
    irrigationWindows: [
      _avoid, _good, _good, _good, _good, _neutral,
      _neutral, _avoid, _avoid, _avoid, _avoid, _avoid
    ],
    sprayingWindows: [
      _avoid, _avoid, _neutral, _neutral, _neutral, _neutral,
      _neutral, _neutral, _caution, _caution, _caution, _avoid
    ],
    fieldWorkWindows: [
      _neutral, _good, _good, _good, _good, _neutral,
      _neutral, _neutral, _avoid, _avoid, _avoid, _avoid
    ],
    fieldWorkStatus: 'Good Conditions',
    summaryVerdict: 'Good day for field work',
    summaryExplanation:
        'Weather conditions are favorable for most farm activities today.',
  ),
  ActionWindowTab.tomorrow: const ActionWindowsState(
    selectedTab: ActionWindowTab.tomorrow,
    irrigationWindows: [
      _avoid, _avoid, _neutral, _neutral, _good, _good,
      _good, _neutral, _avoid, _avoid, _avoid, _avoid
    ],
    sprayingWindows: [
      _avoid, _avoid, _avoid, _neutral, _neutral, _neutral,
      _neutral, _caution, _caution, _avoid, _avoid, _avoid
    ],
    fieldWorkWindows: [
      _avoid, _neutral, _neutral, _good, _good, _good,
      _neutral, _avoid, _avoid, _avoid, _avoid, _avoid
    ],
    fieldWorkStatus: 'Plan for afternoon',
    summaryVerdict: 'A workable day with caution',
    summaryExplanation:
        'Early moisture clears later; plan field work after midday.',
  ),
  ActionWindowTab.sevenDay: const ActionWindowsState(
    selectedTab: ActionWindowTab.sevenDay,
    irrigationWindows: [
      _avoid, _good, _good, _good, _neutral, _neutral,
      _neutral, _avoid, _avoid, _avoid, _avoid, _avoid
    ],
    sprayingWindows: [
      _avoid, _avoid, _neutral, _neutral, _neutral, _neutral,
      _caution, _caution, _caution, _avoid, _avoid, _avoid
    ],
    fieldWorkWindows: [
      _avoid, _neutral, _good, _good, _good, _good,
      _neutral, _neutral, _avoid, _avoid, _avoid, _avoid
    ],
    fieldWorkStatus: 'Mostly favorable',
    summaryVerdict: 'Favorable windows this week',
    summaryExplanation:
        'Use the morning windows for irrigation and plan spraying later in the day.',
  ),
};

final actionWindowsProvider =
    StateNotifierProvider<ActionWindowsNotifier, ActionWindowsState>(
  (ref) => ActionWindowsNotifier(ref),
);
