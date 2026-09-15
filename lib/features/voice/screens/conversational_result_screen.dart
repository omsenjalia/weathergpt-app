import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/markdown_utils.dart';
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
  var _spoke = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_spoke || !mounted) return;
      _spoke = true;
      final spoken =
          MarkdownUtils.spokenSummary('', widget.response.explanation);
      ref.read(voiceProvider.notifier).speak(spoken);
    });
  }

  String get _md {
    var t = widget.response.explanation;
    t = t.replaceAll(RegExp(r'```widget:[\s\S]*?```'), '');
    t = t.replaceAll(RegExp(r'```json[\s\S]*?```'), '');
    final body = t.trim();
    return body.isEmpty ? widget.response.verdict : body;
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.response;
    // Opaque full-screen route — avoids shell bleed / multi-layer ghosting.
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Material(
        color: const Color(0xFF0B1220),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        ref.read(voiceProvider.notifier).cancel();
                        context.go('/home');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Conversation',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    if (r.transcript.trim().isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12, left: 48),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF134E4A),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
                              bottomLeft: Radius.circular(18),
                              bottomRight: Radius.circular(6),
                            ),
                          ),
                          child: Text(
                            r.transcript,
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF152036),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF243149)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF2DD4BF),
                                ),
                                child: const Icon(Icons.auto_awesome,
                                    size: 14, color: Colors.black87),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                r.label.isEmpty ? 'WeatherGPT' : r.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          MarkdownBody(
                            data: _md,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                fontSize: 15.5,
                                height: 1.45,
                                color: Color(0xFFF8FAFC),
                              ),
                              strong: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF8FAFC),
                              ),
                            ),
                          ),
                          if (r.stats.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: r.stats
                                  .map(
                                    (s) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF101A2C),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(s.label,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF64748B))),
                                          Text(s.value,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: s.color ??
                                                    const Color(0xFFF8FAFC),
                                              )),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go('/chat'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF334155)),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Chat'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          ref.read(voiceProvider.notifier).cancel();
                          context.pushReplacement('/voice/listening', extra: {
                            'accent': AppColors.accent,
                          });
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2DD4BF),
                          foregroundColor: Colors.black87,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Ask again'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
