import 'package:flutter/material.dart';

import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';

/// One of the frosted stat cards inside a [GradientHeader], e.g.
/// "3 / Clases hoy" or "96% / Asistencia".
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.value,
    required this.label,
    this.valueColor = Colors.white,
    this.icon,
  });

  final String value;
  final String label;
  final Color valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.teal),
              const SizedBox(height: 6),
            ],
            Text(
              value,
              style: AppTextStyles.statValue.copyWith(color: valueColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.statLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for a row of header stats while they load; with [empty] it
/// shows a dash instead (the figures could not be loaded).
class StatsSkeleton extends StatelessWidget {
  const StatsSkeleton({
    super.key,
    this.count = 3,
    this.height = 78,
    this.gap = 10,
    this.empty = false,
  });

  final int count;
  final double height;
  final double gap;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        count,
        (i) => Expanded(
          child: Container(
            height: height,
            margin: EdgeInsets.only(right: i == count - 1 ? 0 : gap),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
            ),
            child: empty
                ? Text(
                    '—',
                    style: AppTextStyles.h1.copyWith(color: Colors.white38),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
