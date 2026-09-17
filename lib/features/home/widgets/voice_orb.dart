import 'package:flutter/material.dart';

import '../theme/atmosphere_theme.dart';

/// The circular mic button that launches voice input.
class VoiceOrb extends StatelessWidget {
  const VoiceOrb({super.key, required this.palette, required this.onTap});
  final AtmospherePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [palette.orbStart, palette.orbEnd],
          ),
          boxShadow: [
            BoxShadow(
              color: palette.accent.withValues(alpha: 0.5),
              blurRadius: 28,
              spreadRadius: 3,
            ),
          ],
        ),
        child: const Icon(Icons.mic_rounded, color: Colors.black87, size: 32),
      ),
    );
  }
}
