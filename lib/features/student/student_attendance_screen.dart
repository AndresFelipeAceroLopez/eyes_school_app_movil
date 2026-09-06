import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/async_states.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../providers/session_provider.dart';
import '../shared/attendance_history_view.dart';

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
