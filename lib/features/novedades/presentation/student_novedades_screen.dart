import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/features/novedades/presentation/novedad_card.dart';
import 'package:eyes_school/core/widgets/simple_header_scaffold.dart';
import 'package:eyes_school/providers/data_providers.dart';
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
          message: session?.bootstrapWarning ??
              'Tu cuenta no tiene un perfil de estudiante asociado.',
        ),
      );
    }

    final novedadesAsync = ref.watch(novedadesForStudentProvider(studentId));

    return SimpleHeaderScaffold(
      title: 'Mis novedades',
      showBack: false,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(novedadesForStudentProvider(studentId)),
        child: novedadesAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ListView(children: [
            ErrorView(
              error: error,
              onRetry: () => ref.invalidate(novedadesForStudentProvider(studentId)),
            ),
          ]),
          data: (novedades) {
            if (novedades.isEmpty) {
              return ListView(children: const [
                EmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Todo en orden',
                  message: 'No tienes novedades registradas.',
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: novedades.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => NovedadCard(
                novedad: novedades[index],
                showStudent: false,
              ),
            );
          },
        ),
      ),
    );
  }
}
