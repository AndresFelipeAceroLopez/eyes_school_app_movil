import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/async_states.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/novedad_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../core/widgets/weekly_schedule_list.dart';
import '../../providers/data_providers.dart';
import '../../providers/session_provider.dart';

/// Everything about the linked child in one place: their card, their weekly
/// schedule and their news.
///
/// With one child per guardian account there is nothing to pick, so this tab
/// is the child's detail rather than a list.
class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final childId = session?.childId;

    if (childId == null) {
      return SimpleHeaderScaffold(
        title: 'Mi estudiante',
        showBack: false,
        body: EmptyState(
          icon: Icons.family_restroom_rounded,
          title: 'Sin estudiante vinculado',
          message: session?.bootstrapWarning ??
              'Tu cuenta de acudiente aún no está vinculada a un estudiante.',
        ),
      );
    }

    final profileAsync = ref.watch(studentProfileProvider(childId));
    final novedadesAsync = ref.watch(novedadesForStudentProvider(childId));
    final courseId = session?.courseId;
    final scheduleAsync =
        courseId == null ? null : ref.watch(studentWeeklyScheduleProvider(courseId));

    return SimpleHeaderScaffold(
      title: 'Mi estudiante',
      showBack: false,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentProfileProvider(childId));
          ref.invalidate(novedadesForStudentProvider(childId));
          if (courseId != null) ref.invalidate(studentWeeklyScheduleProvider(courseId));
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: profileAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  error: error,
                  compact: true,
                  onRetry: () => ref.invalidate(studentProfileProvider(childId)),
                ),
                data: (child) => InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.push('/students/$childId'),
                  child: SectionCard(
                    child: Row(
                      children: [
                        AvatarCircle(
                          name: child?.name ?? session?.childName ?? 'Estudiante',
                          radius: 26,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                child?.name ?? session?.childName ?? 'Estudiante',
                                style: AppTextStyles.h3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                [child?.grade, child?.jornada, child?.code]
                                    .whereType<String>()
                                    .join(' · '),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: SectionHeader(
                title: 'Novedades',
                trailingText: 'Notas',
                onTrailingTap: () => context.go('/parent/notes'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: novedadesAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  error: error,
                  compact: true,
                  onRetry: () => ref.invalidate(novedadesForStudentProvider(childId)),
                ),
                data: (novedades) => novedades.isEmpty
                    ? const EmptyState(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Todo en orden',
                        message: 'No hay novedades registradas.',
                      )
                    : Column(
                        children: novedades
                            .map((n) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: NovedadCard(novedad: n, showStudent: false),
                                ))
                            .toList(),
                      ),
              ),
            ),
            if (scheduleAsync != null)
              scheduleAsync.when(
                loading: () => const LoadingView(),
                error: (_, _) => const SizedBox.shrink(),
                data: (sessions) => sessions.isEmpty
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: SectionHeader(title: 'Horario semanal'),
                          ),
                          WeeklyScheduleList(sessions: sessions),
                        ],
                      ),
              ),
            if (session?.childDocument != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  'Documento del estudiante: ${session!.childDocument}'
                  '${session.relationship == null ? '' : ' · Parentesco: ${session.relationship}'}',
                  style: AppTextStyles.caption,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
