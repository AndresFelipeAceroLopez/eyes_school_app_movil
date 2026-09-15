import 'package:eyes_school/features/attendance/domain/attendance.dart';
import 'attendance_record.dart';

/// Aggregated attendance, computed on the client: the API returns raw rows
/// plus a `porcentaje_asistencia` on the dashboards.
class AttendanceSummary {
  const AttendanceSummary({
    required this.percent,
    required this.present,
    required this.absent,
    required this.late,
    this.excused = 0,
  });

  static const empty = AttendanceSummary(percent: 0, present: 0, absent: 0, late: 0);

  final double percent;
  final int present;
  final int absent;
  final int late;
  final int excused;

  int get total => present + absent + late + excused;

  /// Late still counts as attendance; an excused absence is not a fault but is
  /// not a presence either, which is how the web panel reports it.
  static AttendanceSummary of(List<AttendanceRecord> rows) {
    if (rows.isEmpty) return empty;
    var present = 0;
    var absent = 0;
    var late = 0;
    var excused = 0;
    for (final row in rows) {
      switch (row.state) {
        case AttendanceState.present:
          present++;
        case AttendanceState.late:
          late++;
        case AttendanceState.absent:
        case AttendanceState.suspended:
          absent++;
        case AttendanceState.excused:
          excused++;
      }
    }
    return AttendanceSummary(
      percent: ((present + late) / rows.length) * 100,
      present: present,
      absent: absent,
      late: late,
      excused: excused,
    );
  }
}
