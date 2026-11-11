import 'package:flutter/material.dart';

import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/features/attendance/domain/attendance.dart';
import 'package:eyes_school/features/attendance/domain/attendance_record.dart';
import 'package:eyes_school/features/directory/presentation/avatar_circle.dart';

/// One attendance record as a row: avatar, name, kind and time, and the state
/// badge. Shared by the admin home and the day's register.
class AttendanceRecordTile extends StatelessWidget {
  const AttendanceRecordTile({
    super.key,
    required this.row,
    required this.name,
    this.trailing,
  });

  final AttendanceRecord row;

  /// From the local catalog; falls back to «Estudiante N» while it loads.
  final String? name;
  final Widget? trailing;

  static Color stateColor(AttendanceState state) => switch (state) {
    AttendanceState.present => AppColors.tealDark,
    AttendanceState.late => AppColors.orange,
    AttendanceState.excused => AppColors.blue,
    _ => AppColors.pink,
  };

  @override
  Widget build(BuildContext context) {
    final label = (name == null || name!.isEmpty)
        ? 'Estudiante ${row.studentId}'
        : name!;
    final color = stateColor(row.state);
    return Row(
      children: [
        AvatarCircle(name: label, radius: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                [
                  row.kind?.label,
                  if (row.registeredAt != null)
                    TimeOfDay.fromDateTime(row.registeredAt!).format(context),
                ].whereType<String>().join(' · '),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            row.state.label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
