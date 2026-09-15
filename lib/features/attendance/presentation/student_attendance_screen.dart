import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/core/widgets/simple_header_scaffold.dart';
import 'package:eyes_school/providers/session_provider.dart';
import 'package:eyes_school/features/attendance/presentation/attendance_history_view.dart';

/// The student's own attendance history, reached from the "Asistencia" card
/// on the home screen.
class StudentAttendanceScreen extends ConsumerWidget {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final studentId = session?.subjectStudentId;

    return SimpleHeaderScaffold(
      title: 'Mi asistencia',
      body: studentId == null
          ? EmptyState(
              icon: Icons.fact_check_outlined,
              title: 'Perfil de estudiante no encontrado',
              message: session?.bootstrapWarning ??
                  'Tu cuenta no tiene un perfil de estudiante asociado.',
            )
          : AttendanceHistoryView(studentId: studentId),
    );
  }
}
