import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/utils/formatters.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/features/directory/presentation/avatar_circle.dart';
import 'package:eyes_school/core/widgets/gradient_header.dart';
import 'package:eyes_school/core/widgets/quick_action_tile.dart';
import 'package:eyes_school/core/widgets/section_header.dart';
import 'package:eyes_school/core/widgets/stat_pill.dart';
import 'package:eyes_school/features/novedades/domain/novedad.dart';
import 'package:eyes_school/features/academic/domain/class_session.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/session_provider.dart';
import 'package:eyes_school/features/novedades/presentation/novedad_form_screen.dart';
import 'package:eyes_school/features/novedades/presentation/teacher_novedades_screen.dart';
import 'package:eyes_school/features/novedades/domain/severity.dart';
import 'package:eyes_school/core/theme/domain_styles.dart';

class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final user = session?.user;
    final dashboardAsync = ref.watch(teacherDashboardProvider);
    final classesAsync = ref.watch(teacherTodayClassesProvider);
    final novedadesAsync =
        ref.watch(teacherNovedadesProvider(NovedadStatus.pending));
    final classCatalog = ref.watch(teacherClassesProvider).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(teacherDashboardProvider);
          ref.invalidate(teacherWeeklyScheduleProvider);
          ref.invalidate(teacherClassesProvider);
          ref.invalidate(teacherNovedadesProvider);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            GradientHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AvatarCircle(name: user?.name ?? 'Docente', radius: 26),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Docente${user?.subject == null ? '' : ' · ${user!.subject}'}',
                              style: AppTextStyles.statLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Hola, ${user?.firstName ?? ''}',
                              style: AppTextStyles.h1
                                  .copyWith(color: Colors.white, fontSize: 22),
                            ),
                          ],
                        ),
                      ),
                      _NotificationBell(onTap: () => _showNoNotifications(context)),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // The four KPIs come straight from `/dashboard/docente`;
                  // only three fit in the header, so the fourth (grades
                  // registered today) rides along with the quick actions.
                  dashboardAsync.when(
                    data: (data) => Row(
                      children: [
                        StatPill(
                          value: '${classesAsync.valueOrNull?.length ?? 0}',
                          label: 'Clases hoy',
                        ),
                        const SizedBox(width: 10),
                        StatPill(
                          value: '${data.totalStudents}',
                          label: 'Estudiantes',
                        ),
                        const SizedBox(width: 10),
                        StatPill(
                          value: '${data.attendanceToday}',
                          label: 'Asistencias hoy',
                          valueColor: AppColors.teal,
                        ),
                      ],
                    ),
                    loading: () => const _HeaderStatsSkeleton(),
                    error: (_, _) => Row(
                      children: [
                        StatPill(
                          value: '${classesAsync.valueOrNull?.length ?? 0}',
                          label: 'Clases hoy',
                        ),
                        const SizedBox(width: 10),
                        StatPill(value: '${classCatalog.length}', label: 'Asignaciones'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (session?.bootstrapWarning != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _Warning(message: session!.bootstrapWarning!),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text('Acciones rápidas', style: AppTextStyles.h2),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
                children: [
                  QuickActionTile(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Escanear',
                    iconBg: AppColors.statusActiveBg,
                    iconColor: AppColors.tealDark,
                    onTap: () => context.go('/teacher/qr'),
                  ),
                  QuickActionTile(
                    icon: Icons.edit_note_rounded,
                    label: 'Nota',
                    iconBg: AppColors.roleTeacherBg,
                    iconColor: AppColors.roleTeacher,
                    onTap: () => context.go('/teacher/notes'),
                  ),
                  QuickActionTile(
                    icon: Icons.note_add_rounded,
                    label: 'Novedad',
                    iconBg: const Color(0xFFFCEEDD),
                    iconColor: AppColors.orange,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const NovedadFormScreen()),
                    ),
                  ),
                  QuickActionTile(
                    icon: Icons.fact_check_rounded,
                    label: 'Asistencia',
                    iconBg: AppColors.roleStudentBg,
                    iconColor: AppColors.roleStudent,
                    onTap: () => context.go('/teacher/classes'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Clases de hoy', style: AppTextStyles.h2),
                  Text(Formatters.todayLong(DateTime.now()),
                      style: AppTextStyles.bodyMuted),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: classesAsync.when(
                data: (classes) {
                  if (classes.isEmpty) {
                    return const EmptyState(
                      icon: Icons.event_available_rounded,
                      title: 'Sin clases hoy',
                      message: 'No tienes bloques programados para hoy.',
                    );
                  }
                  return Column(
                    children: classes
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _ClassCard(
                                session: c,
                                onPasarLista: () => _openRoster(context, c, classCatalog),
                              ),
                            ))
                        .toList(),
                  );
                },
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  error: error,
                  compact: true,
                  onRetry: () => ref.invalidate(teacherWeeklyScheduleProvider),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SectionHeader(
                title: 'Novedades pendientes',
                trailingText: 'Ver todo',
                onTrailingTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const TeacherNovedadesScreen()),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: novedadesAsync.when(
                data: (novedades) {
                  if (novedades.isEmpty) {
                    return const EmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Todo al día',
                      message: 'No hay novedades pendientes.',
                    );
                  }
                  final visible = novedades.take(4).toList();
                  return SectionCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < visible.length; i++)
                          _NovedadRow(
                            novedad: visible[i],
                            showDivider: i != visible.length - 1,
                          ),
                      ],
                    ),
                  );
                },
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  error: error,
                  compact: true,
                  onRetry: () => ref.invalidate(teacherNovedadesProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A schedule block knows its course and subject, so the matching assignment
  /// is what tells the roll-call screen which class it is taking.
  void _openRoster(BuildContext context, ClassSession session, List<dynamic> classes) {
    for (final item in classes) {
      if (item.courseId == session.courseId && item.subjectId == session.subjectId) {
        context.go('/teacher/classes/${item.assignmentId}/asistencia');
        return;
      }
    }
    context.go('/teacher/classes');
  }

  void _showNoNotifications(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('No tienes notificaciones nuevas.')));
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.orange),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: AppTextStyles.caption)),
        ],
      ),
    );
  }
}

class _HeaderStatsSkeleton extends StatelessWidget {
  const _HeaderStatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (i) => Expanded(
          child: Container(
            height: 78,
            margin: EdgeInsets.only(right: i == 2 ? 0 : 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.session, required this.onPasarLista});

  final ClassSession session;
  final VoidCallback onPasarLista;

  @override
  Widget build(BuildContext context) {
    final inCourse = session.status == ClassStatus.inCourse;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onPasarLista,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: inCourse
              ? const Border(left: BorderSide(color: AppColors.teal, width: 4))
              : null,
          boxShadow: const [
            BoxShadow(color: AppColors.cardShadow, blurRadius: 20, offset: Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        session.time,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: inCourse ? AppColors.tealDark : AppColors.textSecondary,
                        ),
                      ),
                      if (inCourse) ...[
                        const SizedBox(width: 8),
                        Text('· En curso',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.tealDark, fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(session.subject, style: AppTextStyles.h3),
                  const SizedBox(height: 2),
                  Text(session.group, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (inCourse)
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.statusActiveBg,
                  foregroundColor: AppColors.tealDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: onPasarLista,
                child: const Text('Pasar lista',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _NovedadRow extends StatelessWidget {
  const _NovedadRow({required this.novedad, required this.showDivider});

  final Novedad novedad;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AvatarCircle(name: novedad.studentName, radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(novedad.studentName,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(novedad.title, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: novedad.severity.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(Formatters.timeAgo(novedad.date), style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.divider, indent: 16, endIndent: 16),
      ],
    );
  }
}
