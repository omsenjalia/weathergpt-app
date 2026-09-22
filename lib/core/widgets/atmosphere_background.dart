import 'package:flutter/material.dart';

/// The immersive sky-gradient canvas behind non-home screens (chat, voice,
/// settings, onboarding…).
///
/// Home keeps its video atmosphere; every other screen shares this cheaper
/// rendering of the same idea: a deep vertical gradient in the current
/// time-of-day palette plus two slow-drifting colored glows so the app feels
/// alive without a video decoder running. Purely decorative — screen content
/// is layered above by the caller.
class AtmosphereBackground extends StatefulWidget {
  const AtmosphereBackground({
    super.key,
    required this.top,
    required this.mid,
    required this.bottom,
    this.glow = const Color(0xFF2DD4BF),
    this.secondaryGlow = const Color(0xFF38BDF8),
    this.animate = true,
    this.scrim = true,
  });

  final Color top;
  final Color mid;
  final Color bottom;
  final Color glow;
  final Color secondaryGlow;
  final bool animate;

  /// Darkens the lower half so lists and cards stay legible.
  final bool scrim;

  @override
  State<AtmosphereBackground> createState() => _AtmosphereBackgroundState();
}

class _AtmosphereBackgroundState extends State<AtmosphereBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    if (widget.animate) _drift.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant AtmosphereBackground old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_drift.isAnimating) {
      _drift.repeat(reverse: true);
    } else if (!widget.animate && _drift.isAnimating) {
      _drift.stop();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [widget.top, widget.mid, widget.bottom],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _drift,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_drift.value);
              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: -size.width * 0.35 + t * 28,
                    top: -size.height * 0.12 - t * 18,
                    child: _glow(size * 0.9, widget.glow, 0.16),
                  ),
                  Positioned(
                    right: -size.width * 0.30 - t * 24,
                    bottom: -size.height * 0.18 + t * 14,
                    child: _glow(size * 0.8, widget.secondaryGlow, 0.10),
                  ),
                ],
              );
            },
          ),
          if (widget.scrim)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    widget.bottom.withValues(alpha: 0.42),
                    Colors.black.withValues(alpha: 0.30),
                  ],
                  stops: const [0.30, 0.72, 1.0],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _glow(Size s, Color color, double alpha) => IgnorePointer(
        child: Container(
          width: s.width,
          height: s.height,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
            ),
          ),
        ),
      );
}
