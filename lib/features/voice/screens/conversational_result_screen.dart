import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/voice_provider.dart';
import '../widgets/recommendation_card.dart';

class ConversationalResultScreen extends ConsumerStatefulWidget {
  const ConversationalResultScreen({super.key, required this.response});
  final VoiceResponse response;
  @override
  ConsumerState<ConversationalResultScreen> createState() =>
      _ConversationalResultScreenState();
}

class _ConversationalResultScreenState
    extends ConsumerState<ConversationalResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref
        .read(voiceProvider.notifier)
        .speak('${widget.response.verdict}. ${widget.response.explanation}'));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            leading: IconButton(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.arrow_back)),
            title: Text('common.weather_gpt'.tr(), style: const TextStyle(fontSize: 17))),
        body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                              constraints: const BoxConstraints(maxWidth: 290),
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                  color: AppColors.surfaceCardAlt,
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(5))),
                              child: Text(widget.response.transcript))),
                      const SizedBox(height: 16),
                      RecommendationCard(response: widget.response),
                      const SizedBox(height: 12),
                      Row(
                          children: widget.response.stats
                              .map((stat) => Expanded(
                                  child: Padding(
                                      padding: EdgeInsets.only(
                                          right:
                                              stat == widget.response.stats.last
                                                  ? 0
                                                  : 8),
                                      child: _StatCard(stat: stat))))
                              .toList()),
                      const SizedBox(height: 24),
                      Text('voice.next_3_days'.tr(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Row(
                          children: widget.response.forecast
                              .map((day) => Expanded(
                                  child: Padding(
                                      padding: EdgeInsets.only(
                                          right: day ==
                                                  widget.response.forecast.last
                                              ? 0
                                              : 8),
                                      child: _DayCard(day: day))))
                              .toList()),
                      const SizedBox(height: 24),
                      OutlinedButton(
                          onPressed: () =>
                              context.push('/researcher/historical'),
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              side: const BorderSide(
                                  color: AppColors.textSecondary),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16))),
                          child: Text('${widget.response.ctaLabel}  →')),
                    ]))),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});
  final ResultStat stat;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      decoration: BoxDecoration(
          color: AppColors.surfaceCardAlt,
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(stat.label,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 5),
        Text(stat.value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: stat.color ?? AppColors.textPrimary))
      ]));
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});
  final ForecastDay day;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle)),
      child: Column(children: [
        Text(day.day,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 7),
        Icon(day.icon, color: AppColors.statusAmber),
        const SizedBox(height: 7),
        Text(day.temperature,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(day.rainfall,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 11))
      ]));
}
