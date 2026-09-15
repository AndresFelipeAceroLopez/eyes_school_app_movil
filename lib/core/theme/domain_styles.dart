import 'package:flutter/material.dart';

import 'package:eyes_school/features/academic/domain/grade.dart';
import 'package:eyes_school/features/attendance/domain/attendance.dart';
import 'package:eyes_school/features/novedades/domain/severity.dart';
import 'app_colors.dart';

/// How domain concepts look.
///
/// The domain says a grade is 2.5 and a novedad is critical; deciding that one
/// is pink and the other has a rose background is a presentation concern, and
/// it belongs here rather than inside the entities. Keeping it in one place is
/// also what stops the dot on the teacher's home from drifting away from the
/// chip in the admin tray.

extension GradeVisuals on Grade {
  Color get color {
    if (score >= 4.6) return AppColors.teal;
    if (passing) return AppColors.indigo;
    return AppColors.pink;
  }
}

extension SeverityVisuals on NovedadSeverity {
  Color get color => switch (this) {
        NovedadSeverity.low => AppColors.blue,
        NovedadSeverity.medium => AppColors.orange,
        NovedadSeverity.high => AppColors.pink,
        NovedadSeverity.critical => AppColors.pink,
      };

  Color get background => switch (this) {
        NovedadSeverity.low => AppColors.roleStudentBg,
        NovedadSeverity.medium => const Color(0xFFFCEEDD),
        NovedadSeverity.high => const Color(0xFFFFE7EC),
        NovedadSeverity.critical => const Color(0xFFFFD9E1),
      };
}

extension AttendanceStateVisuals on AttendanceState {
  Color get color => switch (this) {
        AttendanceState.present => AppColors.tealDark,
        AttendanceState.late => AppColors.orange,
        AttendanceState.excused => AppColors.blue,
        AttendanceState.absent || AttendanceState.suspended => AppColors.pink,
      };

  IconData get icon => switch (this) {
        AttendanceState.present => Icons.check_rounded,
        AttendanceState.late => Icons.schedule_rounded,
        AttendanceState.excused => Icons.assignment_turned_in_outlined,
        AttendanceState.absent || AttendanceState.suspended => Icons.close_rounded,
      };
}

extension AttendanceMarkVisuals on AttendanceMark {
  Color get color => state.color;

  IconData get icon => switch (this) {
        AttendanceMark.present => Icons.check_rounded,
        AttendanceMark.late => Icons.schedule_rounded,
        AttendanceMark.absent => Icons.close_rounded,
        AttendanceMark.excused => Icons.assignment_turned_in_outlined,
      };
}

extension SyncStateVisuals on SyncState {
  (Color, String) get badge => switch (this) {
        SyncState.sent => (AppColors.tealDark, 'Enviado'),
        SyncState.failed => (AppColors.pink, 'Error'),
        SyncState.sending => (AppColors.blue, 'Enviando'),
        SyncState.duplicate => (AppColors.orange, 'Duplicado'),
        SyncState.pending => (AppColors.textSecondary, 'En cola'),
      };
}
