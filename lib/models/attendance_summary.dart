class AttendanceSummary {
  const AttendanceSummary({
    required this.percent,
    required this.present,
    required this.absent,
    required this.late,
  });

  final double percent;
  final int present;
  final int absent;
  final int late;

  int get total => present + absent + late;
}
