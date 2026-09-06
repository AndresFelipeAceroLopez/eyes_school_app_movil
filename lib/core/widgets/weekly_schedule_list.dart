import 'package:flutter/material.dart';

import '../../domain/entities/class_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'section_header.dart';

const _dayOrder = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];

/// Groups a list of [ClassSession] by [ClassSession.day] and renders one
/// section per day. Shared by the Teacher and Student weekly schedule
/// screens.
class WeeklyScheduleList extends StatelessWidget {
  const WeeklyScheduleList({super.key, required this.sessions, this.onTapSession});

  final List<ClassSession> sessions;
  final ValueChanged<ClassSession>? onTapSession;

  @override
  Widget build(BuildContext context) {
    final byDay = <String, List<ClassSession>>{};
    for (final s in sessions) {
      byDay.putIfAbsent(s.day ?? 'Otro', () => []).add(s);
    }
    final days = byDay.keys.toList()
      ..sort((a, b) => _dayOrder.indexOf(a).compareTo(_dayOrder.indexOf(b)));

    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('Sin clases programadas.', style: AppTextStyles.bodyMuted)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final day in days) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(day, style: AppTextStyles.h3),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: byDay[day]!
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ScheduleRow(session: s, onTap: onTapSession == null ? null : () => onTapSession!(s)),
                      ))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.session, this.onTap});
  final ClassSession session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final done = session.status == ClassStatus.done;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SectionCard(
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(
                session.time,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: done ? AppColors.textSecondary : AppColors.indigo,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.subject, style: AppTextStyles.h3),
                  Text(session.group, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
