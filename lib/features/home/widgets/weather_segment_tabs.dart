import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../theme/atmosphere_theme.dart';

/// Overview / Hourly / 7-day segmented control.
class WeatherSegmentTabs extends StatelessWidget {
  const WeatherSegmentTabs({
    super.key,
    required this.index,
    required this.onChanged,
    required this.palette,
  });
  final int index;
  final ValueChanged<int> onChanged;
  final AtmospherePalette palette;

  @override
  Widget build(BuildContext context) {
    final labels = [
      'home.tab_overview'.tr(),
      'home.tab_hourly'.tr(),
      'home.tab_7day'.tr(),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final sel = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel
                      ? palette.accent.withValues(alpha: 0.22)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: sel ? palette.accent : palette.textMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
