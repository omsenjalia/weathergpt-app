import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ActionWindowTab { today, tomorrow, sevenDay }

enum Suitability { good, caution, avoid, neutral }

class HourlySuitability {
  const HourlySuitability(this.suitability, {this.hours = 1});
  final Suitability suitability;
  final int hours;
}

class ActionWindowsState {
  const ActionWindowsState({
    required this.selectedTab,
    required this.irrigationWindows,
    required this.sprayingWindows,
    required this.fieldWorkWindows,
    required this.fieldWorkStatus,
    required this.summaryVerdict,
    required this.summaryExplanation,
  });
  final ActionWindowTab selectedTab;
  final List<HourlySuitability> irrigationWindows;
  final List<HourlySuitability> sprayingWindows;
  final List<HourlySuitability> fieldWorkWindows;
  final String fieldWorkStatus;
  final String summaryVerdict;
  final String summaryExplanation;
}

class ActionWindowsNotifier extends StateNotifier<ActionWindowsState> {
  ActionWindowsNotifier() : super(_data[ActionWindowTab.today]!);

  void selectTab(ActionWindowTab tab) => state = _data[tab]!;
  Future<void> refresh() async {
    // Session 10 will replace this mocked, API-ready data source.
    state = _data[state.selectedTab]!;
  }
}

const _avoid = HourlySuitability(Suitability.avoid);
const _neutral = HourlySuitability(Suitability.neutral);
const _good = HourlySuitability(Suitability.good);
const _caution = HourlySuitability(Suitability.caution);

final _data = <ActionWindowTab, ActionWindowsState>{
  ActionWindowTab.today: const ActionWindowsState(
    selectedTab: ActionWindowTab.today,
    irrigationWindows: [
      _avoid,
      _good,
      _good,
      _good,
      _good,
      _neutral,
      _neutral,
      _avoid,
      _avoid,
      _avoid,
      _avoid,
      _avoid
    ],
    sprayingWindows: [
      _avoid,
      _avoid,
      _neutral,
      _neutral,
      _neutral,
      _neutral,
      _neutral,
      _neutral,
      _caution,
      _caution,
      _caution,
      _avoid
    ],
    fieldWorkWindows: [
      _neutral,
      _good,
      _good,
      _good,
      _good,
      _neutral,
      _neutral,
      _neutral,
      _avoid,
      _avoid,
      _avoid,
      _avoid
    ],
    fieldWorkStatus: 'Good Conditions',
    summaryVerdict: 'Good day for field work',
    summaryExplanation:
        'Weather conditions are favorable for most farm activities today.',
  ),
  ActionWindowTab.tomorrow: const ActionWindowsState(
    selectedTab: ActionWindowTab.tomorrow,
    irrigationWindows: [
      _avoid,
      _avoid,
      _neutral,
      _neutral,
      _good,
      _good,
      _good,
      _neutral,
      _avoid,
      _avoid,
      _avoid,
      _avoid
    ],
    sprayingWindows: [
      _avoid,
      _avoid,
      _avoid,
      _neutral,
      _neutral,
      _neutral,
      _neutral,
      _caution,
      _caution,
      _avoid,
      _avoid,
      _avoid
    ],
    fieldWorkWindows: [
      _avoid,
      _neutral,
      _neutral,
      _good,
      _good,
      _good,
      _neutral,
      _avoid,
      _avoid,
      _avoid,
      _avoid,
      _avoid
    ],
    fieldWorkStatus: 'Plan for afternoon',
    summaryVerdict: 'A workable day with caution',
    summaryExplanation:
        'Early moisture clears later; plan field work after midday.',
  ),
  ActionWindowTab.sevenDay: const ActionWindowsState(
    selectedTab: ActionWindowTab.sevenDay,
    irrigationWindows: [
      _avoid,
      _good,
      _good,
      _good,
      _neutral,
      _neutral,
      _neutral,
      _avoid,
      _avoid,
      _avoid,
      _avoid,
      _avoid
    ],
    sprayingWindows: [
      _avoid,
      _avoid,
      _neutral,
      _neutral,
      _neutral,
      _neutral,
      _caution,
      _caution,
      _caution,
      _avoid,
      _avoid,
      _avoid
    ],
    fieldWorkWindows: [
      _avoid,
      _neutral,
      _good,
      _good,
      _good,
      _good,
      _neutral,
      _neutral,
      _avoid,
      _avoid,
      _avoid,
      _avoid
    ],
    fieldWorkStatus: 'Mostly favorable',
    summaryVerdict: 'Favorable windows this week',
    summaryExplanation:
        'Use the morning windows for irrigation and plan spraying later in the day.',
  ),
};

final actionWindowsProvider =
    StateNotifierProvider<ActionWindowsNotifier, ActionWindowsState>(
  (ref) => ActionWindowsNotifier(),
);
