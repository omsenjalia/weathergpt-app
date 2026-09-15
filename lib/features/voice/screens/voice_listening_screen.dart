import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../conversation/widgets/conversation_chrome.dart';
import '../providers/voice_provider.dart';

class VoiceListeningScreen extends ConsumerStatefulWidget {
  const VoiceListeningScreen({super.key, this.accent, this.prompt});
  final Color? accent;
  final String? prompt;

  @override
  ConsumerState<VoiceListeningScreen> createState() =>
      _VoiceListeningScreenState();
}

class _VoiceListeningScreenState extends ConsumerState<VoiceListeningScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  var _started = false;

  Color get _accent => widget.accent ?? AppColors.statusAmber;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_started) {
        _started = true;
        final prompt = widget.prompt?.trim();
        if (prompt != null && prompt.isNotEmpty) {
          ref.read(voiceProvider.notifier).submitQuery(prompt);
        } else {
          ref.read(voiceProvider.notifier).startListening();
        }
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _onDone(VoiceState state) {
    final response = state.response;
    if (response != null && mounted) {
      context.pushReplacement('/voice/result', extra: response);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<VoiceState>(voiceProvider, (prev, next) {
      if (next.status == VoiceStatus.done && next.response != null) {
        _onDone(next);
      }
    });

    final state = ref.watch(voiceProvider);
    final isListening = state.status == VoiceStatus.listening;
    final isProcessing = state.status == VoiceStatus.processing;
    final isError = state.status == VoiceStatus.error;

    final statusLabel = isError
        ? (state.errorMessage ?? 'Something went wrong')
        : isProcessing
            ? 'Thinking…'
            : isListening
                ? 'Listening…'
                : 'Ready';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          ConversationBackdrop(accent: _accent),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      ref.read(voiceProvider.notifier).cancel();
                      context.pop();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                const Spacer(flex: 2),
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    return SizedBox(
                      height: 220,
                      width: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          for (var i = 0; i < 3; i++)
                            _PulseRing(
                              progress: (_pulse.value + i * 0.28) % 1.0,
                              accent: _accent,
                              active: isListening,
                            ),
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  _accent,
                                  _accent.withValues(alpha: 0.7),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _accent.withValues(alpha: 0.45),
                                  blurRadius: 28,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              isProcessing
                                  ? Icons.hourglass_top_rounded
                                  : isError
                                      ? Icons.error_outline_rounded
                                      : Icons.mic_rounded,
                              size: 40,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                Text(
                  statusLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Text(
                    state.transcript.isEmpty
                        ? (isListening
                            ? 'Ask about weather, rain, or your farm'
                            : '')
                        : state.transcript,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: state.transcript.isEmpty
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                if (isListening)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: TextButton(
                      onPressed: () =>
                          ref.read(voiceProvider.notifier).stopListening(),
                      child: const Text(
                        'I’m done speaking',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                if (isError)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    child: FilledButton(
                      onPressed: () =>
                          ref.read(voiceProvider.notifier).startListening(),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.black87,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Try again'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({
    required this.progress,
    required this.accent,
    required this.active,
  });
  final double progress;
  final Color accent;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scale = 0.55 + progress * 0.7;
    final opacity = active ? (1 - progress) * 0.45 : 0.08;
    return Transform.scale(
      scale: scale,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: accent.withValues(alpha: opacity),
            width: 2,
          ),
        ),
      ),
    );
  }
}
