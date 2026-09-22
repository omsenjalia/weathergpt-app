import 'package:flutter/material.dart';

import 'atmosphere_background.dart';

/// Scaffold with the immersive atmosphere canvas behind a [SafeArea] body.
///
/// Screens that already draw their own sky (Home uses video) do not use this;
/// it is the standard chrome for chat, voice, settings, onboarding and the
/// persona screens.
class AtmosphereScaffold extends StatelessWidget {
  const AtmosphereScaffold({
    super.key,
    required this.top,
    required this.mid,
    required this.bottom,
    this.glow = const Color(0xFF2DD4BF),
    this.secondaryGlow = const Color(0xFF38BDF8),
    this.body,
    this.resizeToAvoidBottomInset = true,
  });

  final Color top;
  final Color mid;
  final Color bottom;
  final Color glow;
  final Color secondaryGlow;
  final Widget? body;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AtmosphereBackground(
            top: top,
            mid: mid,
            bottom: bottom,
            glow: glow,
            secondaryGlow: secondaryGlow,
          ),
          SafeArea(child: body ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}
