import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/utils/formatters.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/features/directory/presentation/avatar_circle.dart';
import 'package:eyes_school/core/widgets/gradient_header.dart';
import 'package:eyes_school/features/academic/presentation/grade_row.dart';
import 'package:eyes_school/core/widgets/quick_action_tile.dart';
import 'package:eyes_school/core/widgets/section_header.dart';
import 'package:eyes_school/features/academic/domain/class_session.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/session_provider.dart';
import 'package:eyes_school/features/novedades/domain/severity.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    if (session == null) return const SizedBox.shrink();
    final user = session.user;
    final studentId = session.studentId;

    final dashboardAsync = ref.watch(studentDashboardProvider);
    final nextClassAsync = ref.watch(studentNextClassProvider);
    final period = ref.watch(currentPeriodProvider);
    final gradesAsync = studentId == null
        ? null
        : ref.watch(gradesForStudentProvider((studentId: studentId, period: period)));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentDashboardProvider);
          ref.invalidate(studentNextClassProvider);
          ref.invalidate(gradesForStudentProvider);
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
                      AvatarCircle(name: user.name, radius: 26),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              [user.grade, user.jornada]
                                  .whereType<String>()
                                  .join(' · '),
                              style: AppTextStyles.statLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Hola, ${user.firstName}',
                              style: AppTextStyles.h1
                                  .copyWith(color: Colors.white, fontSize: 22),
                            ),
                          ],
                        ),
                      ),
                      _Bell(
                        onTap: () => context.go('/student/news'),
                        count: dashboardAsync.valueOrNull?.pendingNovedades ?? 0,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  dashboardAsync.when(
                    loading: () => const _StatsSkeleton(),
                    error: (_, _) => const _StatsSkeleton(empty: true),
                    data: (data) => Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.star_rounded,
                            iconColor: AppColors.teal,
                            label: 'Promedio',
                            value: Formatters.grade(data.average),
                            caption: AcademicPeriods.labelOf(
                                data.currentPeriod ?? period),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.verified_rounded,
                            iconColor: AppColors.teal,
                            label: 'Asistencia',
                            value: Formatters.percent(data.attendancePercent),
                            caption: 'Ver historial',
                            onTap: () => context.push('/student/asistencia'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (session.bootstrapWarning != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 20, color: AppColors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(session.bootstrapWarning!,
                            style: AppTextStyles.caption),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text('Próxima clase', style: AppTextStyles.h2),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: nextClassAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  error: error,
                  compact: true,
                  onRetry: () => ref.invalidate(studentNextClassProvider),
                ),
                data: (next) => next == null
                    ? const EmptyState(
                        icon: Icons.event_available_rounded,
                        title: 'Sin clases hoy',
                        message: 'No hay bloques programados para hoy.',
                      )
                    : _NextClassCard(session: next),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text('Acceso rápido', style: AppTextStyles.h2),
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
                    icon: Icons.qr_code_rounded,
                    label: 'Mi QR',
                    iconBg: AppColors.statusActiveBg,
                    iconColor: AppColors.tealDark,
                    onTap: () => context.push('/my-qr'),
                  ),
                  QuickActionTile(
                    icon: Icons.bar_chart_rounded,
                    label: 'Notas',
                    iconBg: AppColors.roleTeacherBg,
                    iconColor: AppColors.roleTeacher,
                    onTap: () => context.go('/student/notes'),
                  ),
                  QuickActionTile(
                    icon: Icons.calendar_month_rounded,
                    label: 'Horario',
                    iconBg: AppColors.roleStudentBg,
                    iconColor: AppColors.roleStudent,
                    onTap: () => context.go('/student/schedule'),
                  ),
                  QuickActionTile(
                    icon: Icons.notifications_rounded,
                    label: 'Avisos',
                    iconBg: const Color(0xFFFCE4EE),
                    iconColor: AppColors.pink,
                    onTap: () => context.go('/student/news'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: SectionHeader(
                title: 'Mis notas',
                trailingText: 'Ver todas',
                onTrailingTap: () => context.go('/student/notes'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: gradesAsync == null
                  ? const SizedBox.shrink()
                  : gradesAsync.when(
                      loading: () => const LoadingView(),
                      error: (error, _) => ErrorView(
                        error: error,
                        compact: true,
                        onRetry: () => ref.invalidate(gradesForStudentProvider),
                      ),
                      data: (grades) => grades.isEmpty
                          ? const EmptyState(
                              icon: Icons.bar_chart_rounded,
                              title: 'Sin notas todavía',
                              message: 'Aún no hay notas registradas en este periodo.',
                            )
                          : GradesCard(
                              grades: GradesCard.averageBySubject(grades).take(5).toList(),
                              groupBySubject: false,
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextClassCard extends StatelessWidget {
  const _NextClassCard({required this.session});

  final ClassSession session;

  @override
  Widget build(BuildContext context) {
    final inCourse = session.status == ClassStatus.inCourse;
    return SectionCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.roleAdminBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.menu_book_rounded, color: AppColors.tealDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.subject, style: AppTextStyles.h3),
                Text(session.group, style: AppTextStyles.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                session.time,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.indigo, fontWeight: FontWeight.w800),
              ),
              Text(
                inCourse ? 'En curso' : _relative(session),
                style: AppTextStyles.caption.copyWith(
                  color: inCourse ? AppColors.tealDark : AppColors.textSecondary,
                  fontWeight: inCourse ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// "En 45 min" is only true if it is computed; a hard-coded label on a live
  /// schedule is worse than no label.
  String _relative(ClassSession session) {
    final start = session.start;
    if (start == null) return '';
    final now = DateTime.now();
    final minutes = (start.hour * 60 + start.minute) - (now.hour * 60 + now.minute);
    if (minutes <= 0) return 'Finalizada';
    if (minutes < 60) return 'En $minutes min';
    return 'En ${(minutes / 60).floor()} h';
  }
}

class _Bell extends StatelessWidget {
  const _Bell({required this.onTap, required this.count});

  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
          ),
          if (count > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.pink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.caption,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.statLabel),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 26)),
          const SizedBox(height: 2),
          Row(
            children: [
              Flexible(
                child: Text(caption,
                    style: AppTextStyles.statLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded,
                    size: 14, color: AppColors.textOnDarkMuted),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: card,
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton({this.empty = false});

  final bool empty;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        2,
        (i) => Expanded(
          child: Container(
            height: 92,
            margin: EdgeInsets.only(right: i == 1 ? 0 : 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
            ),
            child: empty
                ? Text('—', style: AppTextStyles.h1.copyWith(color: Colors.white38))
                : null,
          ),
        ),
      ),
    );
  }
}
