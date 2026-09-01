import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/gradient_header.dart';
import '../../core/widgets/quick_action_tile.dart';
import '../../core/widgets/section_header.dart';
import '../../models/grade.dart';
import '../../providers/data_providers.dart';
import '../../providers/session_provider.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).value;
    if (user == null) return const SizedBox.shrink();

    final nextClassAsync = ref.watch(studentNextClassProvider);
    final gradesAsync = ref.watch(gradesForStudentProvider(user.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentNextClassProvider);
          ref.invalidate(gradesForStudentProvider(user.id));
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
                            Text('${user.grade} · ${user.jornada}', style: AppTextStyles.statLabel),
                            Text(
                              'Hola, ${user.firstName}',
                              style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 22),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration:
                            BoxDecoration(color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle),
                        child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.star_rounded,
                          iconColor: AppColors.teal,
                          label: 'Promedio',
                          value: '${user.average}',
                          caption: 'Período 2 · 2024',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.verified_rounded,
                          iconColor: AppColors.teal,
                          label: 'Asistencia',
                          value: '${user.attendancePercent?.round()}%',
                          caption: 'Este mes',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text('Próxima clase', style: AppTextStyles.h2),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: nextClassAsync.when(
                data: (session) => SectionCard(
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
                          Text(session.time,
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.indigo, fontWeight: FontWeight.w800)),
                          Text('En 45 min', style: AppTextStyles.caption),
                        ],
                      ),
                    ],
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Text('No se pudo cargar la clase.', style: AppTextStyles.bodyMuted),
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
              child: gradesAsync.when(
                data: (grades) => SectionCard(
                  child: Column(
                    children: [
                      for (int i = 0; i < grades.length; i++) ...[
                        _GradeRow(grade: grades[i]),
                        if (i != grades.length - 1) const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Text('No se pudieron cargar las notas.', style: AppTextStyles.bodyMuted),
              ),
            ),
          ],
        ),
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
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(caption, style: AppTextStyles.statLabel),
        ],
      ),
    );
  }
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({required this.grade});
  final Grade grade;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(grade.subject, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
            Row(
              children: [
                Text(grade.qualitative, style: AppTextStyles.caption),
                const SizedBox(width: 8),
                Text(
                  grade.score.toStringAsFixed(1),
                  style: AppTextStyles.body.copyWith(color: grade.color, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (grade.score / 10).clamp(0, 1),
            minHeight: 8,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation(grade.color),
          ),
        ),
      ],
    );
  }
}
