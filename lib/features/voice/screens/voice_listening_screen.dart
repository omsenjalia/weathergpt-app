import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/voice_provider.dart';

class VoiceListeningScreen extends ConsumerStatefulWidget {
  const VoiceListeningScreen(
      {super.key,
      this.prompt,
      this.accent = AppColors.farmerGreen,
      this.autoStart = true});
  final String? prompt;
  final Color accent;
  final bool autoStart;
  @override
  ConsumerState<VoiceListeningScreen> createState() =>
      _VoiceListeningScreenState();
}

class _VoiceListeningScreenState extends ConsumerState<VoiceListeningScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
    ..repeat();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.prompt?.isNotEmpty == true) {
        ref.read(voiceProvider.notifier).submitQuery(widget.prompt!);
      } else if (widget.autoStart) {
        ref.read(voiceProvider.notifier).startListening();
      }
    });
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(voiceProvider, (_, next) {
      if (next.status == VoiceStatus.done && next.response != null) {
        context.go('/voice/result', extra: next.response);
      }
    });
    final state = ref.watch(voiceProvider);
    final processing = state.status == VoiceStatus.processing;
    return Scaffold(
        body: SafeArea(
            child: AnimatedBuilder(
                animation: _animation,
                builder: (_, __) => Column(children: [
                      const Spacer(flex: 2),
                      Text(processing ? 'voice.thinking'.tr() : 'voice.listening'.tr(),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 26),
                      SizedBox(
                          height: 205,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _WaveBars(
                                    progress: _animation.value,
                                    accent: widget.accent),
                                const SizedBox(width: 10),
                                GestureDetector(
                                    onTap: processing
                                        ? null
                                        : () => ref
                                            .read(voiceProvider.notifier)
                                            .stopListening(),
                                    child: Container(
                                        width: 184,
                                        height: 184,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: widget.accent
                                                .withValues(alpha: .15),
                                            border: Border.all(
                                                color: widget.accent, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                  color: widget.accent
                                                      .withValues(alpha: .55),
                                                  blurRadius: 38,
                                                  spreadRadius:
                                                      processing ? 8 : 2)
                                            ]),
                                        child: Icon(
                                            processing
                                                ? Icons.more_horiz_rounded
                                                : Icons.mic_rounded,
                                            size: 58,
                                            color: AppColors.textPrimary))),
                                const SizedBox(width: 10),
                                Transform.flip(
                                    flipX: true,
                                    child: _WaveBars(
                                        progress: _animation.value,
                                        accent: widget.accent)),
                              ])),
                      const SizedBox(height: 24),
                      Text(
                          state.transcript.isNotEmpty
                              ? '“${state.transcript}”'
                              : processing
                                  ? 'voice.finding_answer'.tr()
                                  : 'voice.speak_now'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 15)),
                      if (state.errorMessage != null)
                        Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                            child: Text(state.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.statusAmber))),
                      const Spacer(flex: 3),
                      OutlinedButton(
                          onPressed: () {
                            ref.read(voiceProvider.notifier).cancel();
                            context.go('/home');
                          },
                          style: OutlinedButton.styleFrom(
                              shape: const CircleBorder(),
                              side: const BorderSide(
                                  color: AppColors.borderSubtle),
                              fixedSize: const Size(50, 50)),
                          child: const Icon(Icons.close,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 26),
                    ]))));
  }
}

class _WaveBars extends StatelessWidget {
  const _WaveBars({required this.progress, required this.accent});
  final double progress;
  final Color accent;
  @override
  Widget build(BuildContext context) => CustomPaint(
      size: const Size(42, 78), painter: _WavePainter(progress, accent));
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.progress, this.accent);
  final double progress;
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final wave = (math.sin((progress * math.pi * 2) + i * .8) + 1) / 2;
      final height = 14.0 + wave * 45;
      final x = i * 8.0 + 2;
      canvas.drawLine(Offset(x, (size.height - height) / 2),
          Offset(x, (size.height + height) / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.progress != progress || old.accent != accent;
}
