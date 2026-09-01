enum NovedadSeverity { low, medium, high }

class Novedad {
  const Novedad({
    required this.studentName,
    required this.studentPhotoUrl,
    required this.title,
    required this.timeAgo,
    required this.severity,
  });

  final String studentName;
  final String studentPhotoUrl;
  final String title;
  final String timeAgo;
  final NovedadSeverity severity;
}
