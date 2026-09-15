import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Soft radial wash behind conversation screens.
class ConversationBackdrop extends StatelessWidget {
  const ConversationBackdrop({super.key, this.accent = AppColors.statusAmber});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.55),
          radius: 1.15,
          colors: [
            accent.withValues(alpha: 0.14),
            AppColors.bgPrimary,
            AppColors.bgPrimary,
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
    );
  }
}

class AiAvatar extends StatelessWidget {
  const AiAvatar({super.key, this.size = 32, this.accent = AppColors.statusAmber});
  final double size;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.95),
            accent.withValues(alpha: 0.45),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Icon(Icons.auto_awesome, size: size * 0.45, color: Colors.black87),
    );
  }
}

class UserBubble extends StatelessWidget {
  const UserBubble({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(left: 48, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.statusAmber.withValues(alpha: 0.22),
              AppColors.statusAmber.withValues(alpha: 0.10),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(6),
          ),
          border: Border.all(
            color: AppColors.statusAmber.withValues(alpha: 0.28),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class AiMessageShell extends StatelessWidget {
  const AiMessageShell({
    super.key,
    required this.child,
    this.accent = AppColors.statusAmber,
    this.showAvatar = true,
  });
  final Widget child;
  final Color accent;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar) ...[
            AiAvatar(accent: accent, size: 30),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard.withValues(alpha: 0.92),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class MetricPill extends StatelessWidget {
  const MetricPill({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class DayChip extends StatelessWidget {
  const DayChip({
    super.key,
    required this.day,
    required this.icon,
    required this.temp,
    required this.rain,
  });
  final String day;
  final IconData icon;
  final String temp;
  final String rain;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Text(day,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Icon(icon, size: 20, color: AppColors.statusAmber),
          const SizedBox(height: 8),
          Text(temp,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(rain,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
