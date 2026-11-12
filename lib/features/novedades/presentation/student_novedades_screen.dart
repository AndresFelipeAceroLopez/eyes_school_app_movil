import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/features/novedades/presentation/student_novedades_list.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/core/widgets/simple_header_scaffold.dart';
import 'package:eyes_school/providers/session_provider.dart';

/// The student'ss own news, read-only. Severity comes from the type catalog.
class StudentNovedadesScreen extends ConsumerWidget {
  const StudentNovedadesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final studentId = session?.subjectStudentId;

    if (studentId == null) {
      return SimpleHeaderScaffold(
        title: 'Mis novedades',
        showBack: false,
        body: EmptyState(
          icon: Icons.notifications_none_rounded,
          title: 'Perfil de estudiante no encontrado',
          message:
              session?.bootstrapWarning ??
              'Tu cuenta no tiene un perfil de estudiante asociado.',
        ),
      );
    }

    return SimpleHeaderScaffold(
      title: 'Mis novedades',
      showBack: false,
      body: StudentNovedadesList(
        studentId: studentId,
        emptyTitle: 'Todo en orden',
        emptyMessage: 'No tienes novedades registradas.',
        topPadding: 20,
      ),
    );
  }
}
