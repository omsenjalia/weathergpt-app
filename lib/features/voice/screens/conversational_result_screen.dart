import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/markdown_utils.dart';
import '../../conversation/widgets/conversation_chrome.dart';
import '../providers/voice_provider.dart';

class ConversationalResultScreen extends ConsumerStatefulWidget {
  const ConversationalResultScreen({super.key, required this.response});
  final VoiceResponse response;

  @override
  ConsumerState<ConversationalResultScreen> createState() =>
      _ConversationalResultScreenState();
}

class _ConversationalResultScreenState
    extends ConsumerState<ConversationalResultScreen> {
  var _speaking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final spoken = MarkdownUtils.spokenSummary(
        '',
        widget.response.explanation,
      );
      await ref.read(voiceProvider.notifier).speak(spoken);
      if (mounted) setState(() => _speaking = false);
    });
  }

  String get _displayMarkdown {
    var text = widget.response.explanation;
    text = text.replaceAll(RegExp(r'```widget:[\s\S]*?```'), '');
    text = text.replaceAll(RegExp(r'```json[\s\S]*?```'), '');
    text = text.replaceAll(RegExp(r'widget:\w+\s*\{[\s\S]*?\}'), '');
    text = text.trim();
    if (text.isEmpty) text = widget.response.verdict;
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.response;
    final accent = r.accent;
    final hasStats = r.stats.isNotEmpty;
    final hasForecast = r.forecast.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          ConversationBackdrop(accent: accent),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  speaking: _speaking,
                  onClose: () => context.go('/home'),
                  onReplay: () async {
                    setState(() => _speaking = true);
                    final spoken = MarkdownUtils.spokenSummary(
                      '',
                      r.explanation,
                    );
                    await ref.read(voiceProvider.notifier).speak(spoken);
                    if (mounted) setState(() => _speaking = false);
                  },
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      UserBubble(text: r.transcript),
                      AiMessageShell(
                        accent: accent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (r.label.isNotEmpty &&
                                r.label != 'Assistant' &&
                                r.label != 'WeatherGPT')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  r.label.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1.1,
                                    fontWeight: FontWeight.w700,
                                    color: accent.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                            MarkdownBody(
                              data: _displayMarkdown,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(
                                  fontSize: 15.5,
                                  height: 1.45,
                                  color: AppColors.textPrimary,
                                ),
                                strong: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                h1: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                h2: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                listBullet: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (hasStats) ...[
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: r.stats
                                    .map(
                                      (s) => MetricPill(
                                        label: s.label,
                                        value: s.value,
                                        color: s.color,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            if (hasForecast) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Next days',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: r.forecast
                                      .map(
                                        (d) => Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: DayChip(
                                            day: d.day,
                                            icon: d.icon,
                                            temp: d.temperature,
                                            rain: d.rainfall,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _BottomActions(
                  accent: accent,
                  onAskAgain: () => context.push('/voice/listening', extra: {
                    'accent': accent,
                  }),
                  onChat: () => context.go('/chat'),
                  onHome: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.speaking,
    required this.onClose,
    required this.onReplay,
  });
  final bool speaking;
  final VoidCallback onClose;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
          const Expanded(
            child: Text(
              'Conversation',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: speaking ? 'Speaking…' : 'Replay',
            onPressed: speaking ? null : onReplay,
            icon: Icon(
              speaking ? Icons.volume_up_rounded : Icons.replay_rounded,
              color: speaking ? AppColors.statusAmber : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.accent,
    required this.onAskAgain,
    required this.onChat,
    required this.onHome,
  });
  final Color accent;
  final VoidCallback onAskAgain;
  final VoidCallback onChat;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onChat,
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('Open chat'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.borderSubtle),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: onAskAgain,
              icon: const Icon(Icons.mic_rounded, size: 18),
              label: const Text('Ask again'),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
