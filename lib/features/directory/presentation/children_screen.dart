import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/features/directory/presentation/avatar_circle.dart';
import 'package:eyes_school/features/novedades/presentation/novedad_card.dart';
import 'package:eyes_school/core/widgets/section_header.dart';
import 'package:eyes_school/core/widgets/simple_header_scaffold.dart';
import 'package:eyes_school/features/academic/presentation/weekly_schedule_list.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/features/directory/domain/linked_child.dart';
import 'package:eyes_school/providers/session_provider.dart';

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
            if (session != null && session.hasSeveralChildren)
              _ChildSelector(
                children: session.children,
                activeId: childId,
                onSelect: (id) => ref.read(sessionProvider.notifier).selectChild(id),
              ),
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
                          name: _displayName(session?.childName, child?.name),
                          radius: 26,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _displayName(session?.childName, child?.name),
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

/// N-05: the guardian may not read `/usuarios/{id}` and `/estudiantes/{id}`
/// carries no names, so the profile name can come back empty. The name the
/// API resolves for the guardian (`nombre_estudiante`) goes first.
String _displayName(String? fromLink, String? fromProfile) {
  for (final candidate in [fromLink, fromProfile]) {
    final value = candidate?.trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return 'Estudiante';
}

/// APP-03: one tappable row per linked child; the active one is highlighted.
class _ChildSelector extends StatelessWidget {
  const _ChildSelector({
    required this.children,
    required this.activeId,
    required this.onSelect,
  });

  final List<LinkedChild> children;
  final int activeId;
  final void Function(int id) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mis hijos', style: AppTextStyles.h3),
          const SizedBox(height: 10),
          for (final c in children)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: c.id == activeId ? AppColors.indigo : AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onSelect(c.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        AvatarCircle(name: c.name, radius: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: c.id == activeId ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              if (c.relationship != null || c.document != null)
                                Text(
                                  [c.relationship, c.document].whereType<String>().join(' · '),
                                  style: AppTextStyles.caption.copyWith(
                                    color: c.id == activeId
                                        ? AppColors.textOnDarkMuted
                                        : AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (c.id == activeId)
                          const Icon(Icons.check_circle_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
