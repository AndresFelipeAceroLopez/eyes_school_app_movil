import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/gradient_header.dart';
import '../../core/widgets/quick_action_tile.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_pill.dart';
import '../../models/class_session.dart';
import '../../models/novedad.dart';
import '../../providers/data_providers.dart';
import '../../providers/session_provider.dart';
import 'class_roster_screen.dart';
import 'novedad_form_screen.dart';
import 'teacher_classes_screen.dart';
import 'teacher_grades_screen.dart';
import 'teacher_novedades_screen.dart';

class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).value;
    final classesAsync = ref.watch(teacherClassesProvider);
    final novedadesAsync = ref.watch(teacherPendingNovedadesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(teacherClassesProvider);
          ref.invalidate(teacherPendingNovedadesProvider);
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
                              'Docente · ${user?.subject ?? ''}',
                              style: AppTextStyles.statLabel,
                            ),
                            Text(
                              'Hola, ${user?.name ?? ''}',
                              style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 22),
                            ),
                          ],
                        ),
                      ),
                      _NotificationBell(onTap: () => _showComingSoon(context)),
                    ],
                  ),
                  const SizedBox(height: 22),
                  classesAsync.when(
                    data: (classes) => Row(
                      children: [
                        StatPill(value: '${classes.length}', label: 'Clases hoy'),
                        const SizedBox(width: 10),
                        const StatPill(value: '72', label: 'Estudiantes'),
                        const SizedBox(width: 10),
                        const StatPill(value: '96%', label: 'Asistencia', valueColor: AppColors.teal),
                      ],
                    ),
                    loading: () => const _HeaderStatsSkeleton(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
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
                    onTap: () => context.push('/teacher/qr'),
                  ),
                  QuickActionTile(
                    icon: Icons.edit_note_rounded,
                    label: 'Nota',
                    iconBg: AppColors.roleTeacherBg,
                    iconColor: AppColors.roleTeacher,
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const TeacherGradesScreen())),
                  ),
                  QuickActionTile(
                    icon: Icons.note_add_rounded,
                    label: 'Novedad',
                    iconBg: const Color(0xFFFCEEDD),
                    iconColor: AppColors.orange,
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const NovedadFormScreen())),
                  ),
                  QuickActionTile(
                    icon: Icons.fact_check_rounded,
                    label: 'Asistencia',
                    iconBg: AppColors.roleStudentBg,
                    iconColor: AppColors.roleStudent,
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const TeacherClassesScreen())),
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
                  Text(Formatters.todayLong(DateTime.now()), style: AppTextStyles.bodyMuted),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: classesAsync.when(
                data: (classes) => Column(
                  children: classes
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _ClassCard(
                              session: c,
                              onPasarLista: () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => ClassRosterScreen(
                                  group: c.group.split(' · ').first,
                                  subject: c.subject,
                                ),
                              )),
                            ),
                          ))
                      .toList(),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Text('No se pudieron cargar las clases.', style: AppTextStyles.bodyMuted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SectionHeader(
                title: 'Novedades pendientes',
                trailingText: 'Ver todo',
                onTrailingTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const TeacherNovedadesScreen())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: novedadesAsync.when(
                data: (novedades) => SectionCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < novedades.length; i++)
                        _NovedadRow(novedad: novedades[i], showDivider: i != novedades.length - 1),
                    ],
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Text('No se pudieron cargar las novedades.', style: AppTextStyles.bodyMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('No tienes notificaciones nuevas.')));
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
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: inCourse ? const Border(left: BorderSide(color: AppColors.teal, width: 4)) : null,
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
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.tealDark, fontWeight: FontWeight.w700)),
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
              child: const Text('Pasar lista', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          else
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
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
    final dotColor = switch (novedad.severity) {
      NovedadSeverity.high => AppColors.pink,
      NovedadSeverity.medium => AppColors.orange,
      NovedadSeverity.low => AppColors.blue,
    };
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
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
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
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(height: 6),
                  Text(novedad.timeAgo, style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: AppColors.divider, indent: 16, endIndent: 16),
      ],
    );
  }
}
