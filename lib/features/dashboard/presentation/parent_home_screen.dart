import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/utils/formatters.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/features/directory/presentation/avatar_circle.dart';
import 'package:eyes_school/features/novedades/presentation/novedad_card.dart';
import 'package:eyes_school/core/widgets/quick_action_tile.dart';
import 'package:eyes_school/core/widgets/section_header.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/session_provider.dart';

/// Guardian home: the linked child's card plus their most recent news.
///
/// `GET /padres/me` returns one child per guardian account, so there is no
/// child picker. The session still models it as an "active child", which is
/// what makes supporting several later a purely additive change.
class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    if (session == null) return const SizedBox.shrink();
    final user = session.user;
    final childId = session.childId;

    final dashboardAsync = ref.watch(parentDashboardProvider);
    final novedadesAsync =
        childId == null ? null : ref.watch(novedadesForStudentProvider(childId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(parentDashboardProvider);
          if (childId != null) ref.invalidate(novedadesForStudentProvider(childId));
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 16, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.headerGradient,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
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
                              session.relationship == null
                                  ? 'Padre / Acudiente'
                                  : '${session.relationship} · Acudiente',
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
                      InkWell(
                        onTap: () => context.go('/parent/children'),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_none_rounded,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(width: 3, height: 16, color: AppColors.teal),
                      const SizedBox(width: 8),
                      Text('EYESCHOOL',
                          style: AppTextStyles.statLabel
                              .copyWith(letterSpacing: 2, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            if (childId == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: EmptyState(
                  icon: Icons.family_restroom_rounded,
                  title: 'Sin estudiante vinculado',
                  message: session.bootstrapWarning ??
                      'Tu cuenta de acudiente aún no está vinculada a un estudiante. '
                          'Pide a un administrador que la vincule.',
                ),
              )
            else ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: SectionHeader(title: 'Mi estudiante'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: dashboardAsync.when(
                  loading: () => const LoadingView(),
                  error: (error, _) => ErrorView(
                    error: error,
                    compact: true,
                    onRetry: () => ref.invalidate(parentDashboardProvider),
                  ),
                  data: (data) => _ChildCard(
                    name: data.studentName ??
                        session.childName ??
                        'Estudiante $childId',
                    document: session.childDocument,
                    average: Formatters.grade(data.average),
                    attendance: Formatters.percent(data.attendancePercent),
                    pending: data.pendingNovedades,
                    onTap: () => context.push('/students/$childId'),
                  ),
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
                      icon: Icons.bar_chart_rounded,
                      label: 'Notas',
                      iconBg: AppColors.roleTeacherBg,
                      iconColor: AppColors.roleTeacher,
                      onTap: () => context.go('/parent/notes'),
                    ),
                    QuickActionTile(
                      icon: Icons.fact_check_rounded,
                      label: 'Asistencia',
                      iconBg: AppColors.statusActiveBg,
                      iconColor: AppColors.tealDark,
                      onTap: () => context.go('/parent/attendance'),
                    ),
                    QuickActionTile(
                      icon: Icons.calendar_month_rounded,
                      label: 'Horario',
                      iconBg: AppColors.roleStudentBg,
                      iconColor: AppColors.roleStudent,
                      onTap: () => context.go('/parent/children'),
                    ),
                    QuickActionTile(
                      icon: Icons.notifications_rounded,
                      label: 'Novedades',
                      iconBg: const Color(0xFFFCE4EE),
                      iconColor: AppColors.pink,
                      onTap: () => context.go('/parent/children'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: SectionHeader(
                  title: 'Novedades recientes',
                  trailingText: 'Ver todo',
                  onTrailingTap: () => context.go('/parent/children'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: novedadesAsync!.when(
                  loading: () => const LoadingView(),
                  error: (error, _) => ErrorView(
                    error: error,
                    compact: true,
                    onRetry: () => ref.invalidate(novedadesForStudentProvider(childId)),
                  ),
                  data: (novedades) {
                    if (novedades.isEmpty) {
                      return const EmptyState(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Todo en orden',
                        message: 'No hay novedades registradas.',
                      );
                    }
                    return Column(
                      children: novedades
                          .take(3)
                          .map((n) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: NovedadCard(novedad: n, showStudent: false),
                              ))
                          .toList(),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.name,
    required this.document,
    required this.average,
    required this.attendance,
    required this.pending,
    required this.onTap,
  });

  final String name;
  final String? document;
  final String average;
  final String attendance;
  final int pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarCircle(name: name, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: AppTextStyles.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (document != null)
                        Text(document!, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricChip(
                      label: 'Promedio', value: average, color: AppColors.tealDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricChip(
                      label: 'Asistencia', value: attendance, color: AppColors.indigo),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricChip(
                    label: 'Novedades',
                    value: '$pending',
                    color: pending > 0 ? AppColors.pink : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption, maxLines: 1),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.h3.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
