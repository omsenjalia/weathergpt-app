import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
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

  Color get _accent => widget.accent ?? AppColors.accent;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_started) return;
      _started = true;
      final p = widget.prompt?.trim();
      if (p != null && p.isNotEmpty) {
        ref.read(voiceProvider.notifier).submitQuery(p);
      } else {
        ref.read(voiceProvider.notifier).startListening();
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<VoiceState>(voiceProvider, (_, next) {
      if (next.status == VoiceStatus.done && next.response != null && mounted) {
        context.pushReplacement('/voice/result', extra: next.response);
      }
    });

    final state = ref.watch(voiceProvider);
    final listening = state.status == VoiceStatus.listening;
    final processing = state.status == VoiceStatus.processing;
    final error = state.status == VoiceStatus.error;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    _accent.withValues(alpha: 0.16),
                    AppColors.bgPrimary,
                  ],
                ),
              ),
            ),
          ),
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
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) {
                    return SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Transform.scale(
                              scale: 0.55 + ((_pulse.value + i * 0.3) % 1) * 0.7,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _accent.withValues(
                                      alpha: listening
                                          ? (1 - ((_pulse.value + i * 0.3) % 1)) *
                                              0.4
                                          : 0.08,
                                    ),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [_accent, AppColors.sky],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _accent.withValues(alpha: 0.4),
                                  blurRadius: 28,
                                ),
                              ],
                            ),
                            child: Icon(
                              error
                                  ? Icons.error_outline
                                  : processing
                                      ? Icons.hourglass_top_rounded
                                      : Icons.mic_rounded,
                              size: 36,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  error
                      ? (state.errorMessage ?? 'Error')
                      : processing
                          ? 'Thinking…'
                          : listening
                              ? 'Listening…'
                              : 'Ready',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    state.transcript.isEmpty
                        ? 'Ask about weather, rain, or farming'
                        : state.transcript,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: state.transcript.isEmpty
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                const Spacer(),
                if (listening)
                  TextButton(
                    onPressed: () =>
                        ref.read(voiceProvider.notifier).stopListening(),
                    child: const Text('Done speaking'),
                  ),
                if (error)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: FilledButton(
                      onPressed: () =>
                          ref.read(voiceProvider.notifier).startListening(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black87,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Try again'),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
