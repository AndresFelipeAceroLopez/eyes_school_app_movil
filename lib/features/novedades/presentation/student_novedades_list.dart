import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/features/novedades/presentation/novedad_card.dart';
import 'package:eyes_school/providers/data_providers.dart';

/// The novedades of one student with pull-to-refresh, error with retry and an
/// empty state. Shared by the student's own tab and the student profile.
class StudentNovedadesList extends ConsumerWidget {
  const StudentNovedadesList({
    super.key,
    required this.studentId,
    required this.emptyTitle,
    required this.emptyMessage,
    this.topPadding = 16,
  });

  final int studentId;
  final String emptyTitle;
  final String emptyMessage;
  final double topPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novedadesAsync = ref.watch(novedadesForStudentProvider(studentId));
    void retry() => ref.invalidate(novedadesForStudentProvider(studentId));

    return RefreshIndicator(
      onRefresh: () async => retry(),
      child: novedadesAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ListView(
          children: [ErrorView(error: error, onRetry: retry)],
        ),
        data: (novedades) {
          if (novedades.isEmpty) {
            return ListView(
              children: [
                EmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: emptyTitle,
                  message: emptyMessage,
                ),
              ],
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(20, topPadding, 20, 32),
            itemCount: novedades.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                NovedadCard(novedad: novedades[index], showStudent: false),
          );
        },
      ),
    );
  }
}
