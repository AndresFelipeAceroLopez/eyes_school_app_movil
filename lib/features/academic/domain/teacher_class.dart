/// One `AsignacionOut` resolved against the course and subject catalogs: the
/// unit the teacher role works in ("Matemáticas · 10-A"). Everything a teacher
/// may register is scoped to one of these.
class TeacherClass {
  const TeacherClass({
    required this.assignmentId,
    required this.courseId,
    required this.subjectId,
    required this.courseName,
    required this.subjectName,
    required this.active,
    this.shift,
    this.studentCount,
  });

  final int assignmentId;
  final int courseId;
  final int subjectId;
  final String courseName;
  final String subjectName;
  final bool active;
  final String? shift;

  /// Filled in only where the roster has already been fetched.
  final int? studentCount;

  TeacherClass withStudentCount(int count) => TeacherClass(
        assignmentId: assignmentId,
        courseId: courseId,
        subjectId: subjectId,
        courseName: courseName,
        subjectName: subjectName,
        active: active,
        shift: shift,
        studentCount: count,
      );
}
