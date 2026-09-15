import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/markdown_utils.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Body text only — skip the card title/verdict.
      final spoken = MarkdownUtils.spokenSummary(
        '',
        widget.response.explanation,
      );
      ref.read(voiceProvider.notifier).speak(spoken);
    });
  }

  /// Strip raw widget JSON blobs that look ugly in markdown.
  String get _displayMarkdown {
    var text = widget.response.explanation;
    text = text.replaceAll(RegExp(r'```widget:[\s\S]*?```'), '');
    text = text.replaceAll(RegExp(r'```json[\s\S]*?```'), '');
    text = text.replaceAll(RegExp(r'widget:\w+\s*\{[\s\S]*?\}'), '');
    return text.trim().isEmpty ? widget.response.verdict : text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final response = widget.response;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          'common.weather_gpt'.tr(),
          style: const TextStyle(fontSize: 17),
        ),
      ),
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
                      bottomRight: Radius.circular(5),
                    ),
                  ),
                  child: Text(response.transcript),
                ),
              ),
              const SizedBox(height: 16),
              RecommendationCard(response: response),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: MarkdownBody(
                  data: _displayMarkdown,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                    h1: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    h2: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    strong: const TextStyle(fontWeight: FontWeight.w700),
                    listBullet: const TextStyle(color: AppColors.textSecondary),
                    code: const TextStyle(
                      backgroundColor: AppColors.surfaceCardAlt,
                      fontSize: 12,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: AppColors.surfaceCardAlt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: response.stats
                    .map(
                      (stat) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: stat == response.stats.last ? 0 : 8,
                          ),
                          child: _StatCard(stat: stat),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'voice.next_3_days'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                children: response.forecast
                    .map(
                      (day) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: day == response.forecast.last ? 0 : 8,
                          ),
                          child: _DayCard(day: day),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.push('/researcher/historical'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  side: const BorderSide(color: AppColors.textSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('${response.ctaLabel}  →'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});
  final ResultStat stat;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surfaceCardAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stat.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 5),
            Text(
              stat.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: stat.color ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
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
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Text(
              day.day,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 7),
            Icon(day.icon, color: AppColors.statusAmber),
            const SizedBox(height: 7),
            Text(day.temperature, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              day.rainfall,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      );
}
