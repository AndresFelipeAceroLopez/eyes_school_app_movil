import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/attendance_donut.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/gradient_header.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_pill.dart';
import '../../data/mock/mock_seed.dart';
import '../../providers/data_providers.dart';
import '../../providers/session_provider.dart';
import 'admin_activity_screen.dart';
import 'management_screen.dart';
import 'reports_screen.dart';
import 'schedules_screen.dart';
import 'subjects_screen.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).value;
    final attendanceAsync = ref.watch(adminAttendanceTodayProvider);
    final activityAsync = ref.watch(adminRecentActivityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminAttendanceTodayProvider);
          ref.invalidate(adminRecentActivityProvider);
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
                      AvatarCircle(name: user?.name ?? 'Admin', radius: 26),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Administrador · ${user?.institution ?? ''}',
                                style: AppTextStyles.statLabel),
                            Text(
                              'Hola, ${user?.name ?? ''}',
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(width: 3, height: 16, color: AppColors.teal),
                      const SizedBox(width: 8),
                      Text('EYESCHOOL',
                          style: AppTextStyles.statLabel.copyWith(letterSpacing: 2, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      StatPill(value: '${MockSeed.adminStudentCount}', label: 'Estudiantes'),
                      const SizedBox(width: 10),
                      StatPill(value: '${MockSeed.adminTeacherCount}', label: 'Docentes'),
                      const SizedBox(width: 10),
                      StatPill(
                        value: '${MockSeed.adminAlertCount}',
                        label: 'Alertas',
                        valueColor: AppColors.pink,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: SectionHeader(
                title: 'Indicadores',
                trailingText: 'Detalles',
                onTrailingTap: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: attendanceAsync.when(
                data: (attendance) => Row(
                  children: [
                    Expanded(
                      child: _IndicatorCard(
                        icon: Icons.trending_up_rounded,
                        iconBg: AppColors.statusActiveBg,
                        iconColor: AppColors.tealDark,
                        value: '${attendance.percent}%',
                        label: 'Asistencia hoy',
                        footer: '+1.3% vs ayer',
                        footerColor: AppColors.tealDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _IndicatorCard(
                        icon: Icons.description_rounded,
                        iconBg: AppColors.roleTeacherBg,
                        iconColor: AppColors.roleTeacher,
                        value: '${MockSeed.adminGradesRegistered}',
                        label: 'Notas registradas',
                        footer: 'Este período',
                        footerColor: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _IndicatorCard(
                        icon: Icons.warning_amber_rounded,
                        iconBg: const Color(0xFFFCEEDD),
                        iconColor: AppColors.orange,
                        value: '${MockSeed.adminIncidents}',
                        label: 'Incidencias',
                        footer: '${MockSeed.adminIncidentsUnresolved} sin resolver',
                        footerColor: AppColors.orange,
                      ),
                    ),
                  ],
                ),
                loading: () => const SizedBox(height: 110, child: Center(child: CircularProgressIndicator())),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: attendanceAsync.when(
                data: (attendance) => SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Asistencia hoy', style: AppTextStyles.h3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.statusActiveBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration:
                                      const BoxDecoration(color: AppColors.tealDark, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                Text('En vivo',
                                    style: AppTextStyles.caption
                                        .copyWith(color: AppColors.tealDark, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text('Actualizado hace 5 min', style: AppTextStyles.caption),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          AttendanceDonut(percent: attendance.percent),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: [
                                _LegendRow(
                                  color: AppColors.teal,
                                  label: 'Presentes',
                                  value: '${attendance.present}',
                                ),
                                const SizedBox(height: 10),
                                _LegendRow(
                                  color: AppColors.pink,
                                  label: 'Ausentes',
                                  value: '${attendance.absent}',
                                ),
                                const SizedBox(height: 10),
                                _LegendRow(
                                  color: AppColors.orange,
                                  label: 'Tardanzas',
                                  value: '${attendance.late}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.divider),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () =>
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
                          icon: const Icon(Icons.assignment_outlined, size: 18),
                          label: const Text('Ver reporte completo'),
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: SectionHeader(
                title: 'Acceso rápido',
                trailingText: 'Ver todo',
                onTrailingTap: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManagementScreen())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: [
                  _AccessTile(
                    icon: Icons.people_alt_rounded,
                    iconBg: AppColors.roleStudentBg,
                    iconColor: AppColors.roleStudent,
                    title: 'Usuarios',
                    subtitle: '48 activos',
                    onTap: () => context.push('/admin/management/users'),
                  ),
                  _AccessTile(
                    icon: Icons.notifications_active_rounded,
                    iconBg: const Color(0xFFFCEEDD),
                    iconColor: AppColors.orange,
                    title: 'Novedades',
                    subtitle: '3 pendientes',
                    onTap: () => context.go('/admin/news'),
                  ),
                  _AccessTile(
                    icon: Icons.calendar_month_rounded,
                    iconBg: AppColors.roleAdminBg,
                    iconColor: AppColors.tealDark,
                    title: 'Horarios',
                    subtitle: 'Ver calendario',
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SchedulesScreen())),
                  ),
                  _AccessTile(
                    icon: Icons.menu_book_rounded,
                    iconBg: AppColors.roleTeacherBg,
                    iconColor: AppColors.roleTeacher,
                    title: 'Materias',
                    subtitle: '18 materias',
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubjectsScreen())),
                  ),
                  _AccessTile(
                    icon: Icons.bar_chart_rounded,
                    iconBg: AppColors.roleStudentBg,
                    iconColor: AppColors.roleStudent,
                    title: 'Reportes',
                    subtitle: 'Generar reporte',
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
                  ),
                  _AccessTile(
                    icon: Icons.settings_rounded,
                    iconBg: const Color(0xFFF1F1F6),
                    iconColor: AppColors.textSecondary,
                    title: 'Configuración',
                    subtitle: 'Sistema',
                    onTap: () => context.go('/admin/profile'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: SectionHeader(
                title: 'Actividad reciente',
                trailingText: 'Ver todo',
                onTrailingTap: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminActivityScreen())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: activityAsync.when(
                data: (activity) => SectionCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < activity.length; i++)
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: activity[i].iconBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(activity[i].icon, size: 20, color: activity[i].iconColor),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(activity[i].title,
                                            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                                        Text(activity[i].subtitle, style: AppTextStyles.caption),
                                      ],
                                    ),
                                  ),
                                  Text(activity[i].timeAgo, style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                            if (i != activity.length - 1)
                              const Divider(height: 1, color: AppColors.divider, indent: 16, endIndent: 16),
                          ],
                        ),
                    ],
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Text('No se pudo cargar la actividad.', style: AppTextStyles.bodyMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.footer,
    required this.footerColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final String footer;
  final Color footerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.h2.copyWith(fontSize: 19)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption, maxLines: 2),
          const SizedBox(height: 6),
          Text(footer, style: AppTextStyles.caption.copyWith(color: footerColor, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.body)),
        Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _AccessTile extends StatelessWidget {
  const _AccessTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(height: 8),
              Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700), maxLines: 1),
              Text(subtitle, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
