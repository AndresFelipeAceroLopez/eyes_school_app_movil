import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import 'admin_novedades_screen.dart';
import 'reports_screen.dart';
import 'schedules_screen.dart';
import 'subjects_screen.dart';

/// Hub for everything the admin can consult from a phone.
///
/// The tiles that would create or edit records are absent on purpose: the plan
/// keeps user, course and schedule management in the web panel, where tables
/// and long forms belong.
class ManagementScreen extends ConsumerWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectCount = ref.watch(subjectsProvider).valueOrNull?.length;
    final courseCount = ref.watch(coursesProvider).valueOrNull?.length;
    final studentCount = ref.watch(studentCatalogProvider).size;
    final pending = ref.watch(attendanceQueueProvider).pendingCount;

    return SimpleHeaderScaffold(
      title: 'Gestión',
      showBack: false,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(subjectsProvider);
          ref.invalidate(coursesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            _MenuTile(
              icon: Icons.people_alt_rounded,
              iconBg: AppColors.roleStudentBg,
              iconColor: AppColors.roleStudent,
              title: 'Directorio',
              subtitle: studentCount == 0
                  ? 'Estudiantes, profesores y acudientes'
                  : '$studentCount estudiantes en caché local',
              onTap: () => context.push('/admin/management/users'),
            ),
            _MenuTile(
              icon: Icons.groups_rounded,
              iconBg: AppColors.roleTeacherBg,
              iconColor: AppColors.roleTeacher,
              title: 'Registro masivo',
              subtitle: 'Asistencia de un curso completo',
              onTap: () => context.push('/admin/masivo'),
            ),
            _MenuTile(
              icon: Icons.fact_check_rounded,
              iconBg: AppColors.statusActiveBg,
              iconColor: AppColors.tealDark,
              title: 'Registro del día',
              subtitle: 'Asistencia registrada hoy',
              onTap: () => context.push('/admin/dia'),
            ),
            _MenuTile(
              icon: Icons.cloud_sync_rounded,
              iconBg: pending > 0 ? const Color(0xFFFFE7EC) : const Color(0xFFF1F1F6),
              iconColor: pending > 0 ? AppColors.pink : AppColors.textSecondary,
              title: 'Pendientes por sincronizar',
              subtitle: pending == 0
                  ? 'Todo sincronizado con el servidor'
                  : '$pending registro(s) esperando envío',
              onTap: () => context.push('/admin/qr/pendientes'),
            ),
            _MenuTile(
              icon: Icons.notifications_active_rounded,
              iconBg: const Color(0xFFFCEEDD),
              iconColor: AppColors.orange,
              title: 'Novedades',
              subtitle: 'Incidencias registradas en todo el colegio',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AdminNovedadesScreen()),
              ),
            ),
            _MenuTile(
              icon: Icons.calendar_month_rounded,
              iconBg: AppColors.roleAdminBg,
              iconColor: AppColors.tealDark,
              title: 'Horarios',
              subtitle: courseCount == null
                  ? 'Calendario de clases por curso'
                  : '$courseCount cursos activos',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SchedulesScreen()),
              ),
            ),
            _MenuTile(
              icon: Icons.menu_book_rounded,
              iconBg: AppColors.roleTeacherBg,
              iconColor: AppColors.roleTeacher,
              title: 'Materias',
              subtitle: subjectCount == null
                  ? 'Catálogo académico'
                  : '$subjectCount materias activas',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SubjectsScreen()),
              ),
            ),
            _MenuTile(
              icon: Icons.bar_chart_rounded,
              iconBg: AppColors.roleStudentBg,
              iconColor: AppColors.roleStudent,
              title: 'Reportes',
              subtitle: 'Consulta y descarga de reportes generados',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ReportsScreen()),
              ),
            ),
            _MenuTile(
              icon: Icons.settings_rounded,
              iconBg: const Color(0xFFF1F1F6),
              iconColor: AppColors.textSecondary,
              title: 'Mi cuenta',
              subtitle: 'Datos personales y contraseña',
              onTap: () => context.go('/admin/profile'),
            ),
            const SizedBox(height: 8),
            Text(
              'La creación y edición de usuarios, cursos y horarios se realiza '
              'desde el panel web.',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: iconBg, borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.h3),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
