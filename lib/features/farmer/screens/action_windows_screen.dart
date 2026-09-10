import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../providers/action_windows_provider.dart';
import '../widgets/time_window_bar.dart';

class ActionWindowsScreen extends ConsumerWidget {
  const ActionWindowsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(actionWindowsProvider);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Farm Action Windows',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              Text('Anand, Gujarat',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
      ),
      body: SafeArea(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
            _Tabs(
                selected: state.selectedTab,
                onSelect: ref.read(actionWindowsProvider.notifier).selectTab),
            const SizedBox(height: 20),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Row(children: [
                  Expanded(child: Text('6 AM', style: _scaleStyle)),
                  Expanded(
                      child: Text('12 PM',
                          textAlign: TextAlign.center, style: _scaleStyle)),
                  Expanded(
                      child: Text('6 PM',
                          textAlign: TextAlign.right, style: _scaleStyle)),
                ])),
            const SizedBox(height: 12),
            _ActionRow(
                label: 'Irrigation',
                caption: 'Best: 6–10 AM',
                values: state.irrigationWindows,
                captionColor: AppColors.farmerGreen),
            const SizedBox(height: 18),
            _ActionRow(
                label: 'Spraying',
                caption: 'Best: 2–5 PM',
                values: state.sprayingWindows,
                captionColor: AppColors.statusAmber),
            const SizedBox(height: 18),
            _ActionRow(
                label: 'Field Work',
                caption: state.fieldWorkStatus,
                values: state.fieldWorkWindows,
                captionColor: AppColors.farmerGreen),
            const SizedBox(height: 26),
            AppCard(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.farmerGreen, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(state.summaryVerdict,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 5),
                        Text(state.summaryExplanation,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.35)),
                      ])),
                ])),
          ])),
    );
  }
}

const _scaleStyle = TextStyle(fontSize: 11, color: AppColors.textSecondary);

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onSelect});
  final ActionWindowTab selected;
  final ValueChanged<ActionWindowTab> onSelect;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(18)),
        child: Row(
            children: ActionWindowTab.values.map((tab) {
          final active = tab == selected;
          final label = switch (tab) {
            ActionWindowTab.today => 'Today',
            ActionWindowTab.tomorrow => 'Tomorrow',
            ActionWindowTab.sevenDay => '7 Days'
          };
          return Expanded(
              child: GestureDetector(
                  onTap: () => onSelect(tab),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: active ? AppColors.ctaWhite : Colors.transparent,
                        borderRadius: BorderRadius.circular(15)),
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? AppColors.ctaTextDark
                                : AppColors.textSecondary)),
                  )));
        }).toList()),
      );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow(
      {required this.label,
      required this.caption,
      required this.values,
      required this.captionColor});
  final String label;
  final String caption;
  final List<HourlySuitability> values;
  final Color captionColor;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(caption,
            style: TextStyle(
                fontSize: 12,
                color: captionColor,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 9),
        TimeWindowBar(values: values),
      ]);
}
