import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import 'admin_novedades_screen.dart';
import 'reports_screen.dart';
import 'schedules_screen.dart';
import 'subjects_screen.dart';

class ManagementScreen extends StatelessWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleHeaderScaffold(
      title: 'Gestión',
      showBack: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _MenuTile(
            icon: Icons.people_alt_rounded,
            iconBg: AppColors.roleStudentBg,
            iconColor: AppColors.roleStudent,
            title: 'Usuarios',
            subtitle: 'Docentes, estudiantes, padres y administradores',
            onTap: () => context.push('/admin/management/users'),
          ),
          _MenuTile(
            icon: Icons.notifications_active_rounded,
            iconBg: const Color(0xFFFCEEDD),
            iconColor: AppColors.orange,
            title: 'Novedades',
            subtitle: 'Incidencias registradas en todo el colegio',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AdminNovedadesScreen())),
          ),
          _MenuTile(
            icon: Icons.calendar_month_rounded,
            iconBg: AppColors.roleAdminBg,
            iconColor: AppColors.tealDark,
            title: 'Horarios',
            subtitle: 'Calendario de clases por grupo',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SchedulesScreen())),
          ),
          _MenuTile(
            icon: Icons.menu_book_rounded,
            iconBg: AppColors.roleTeacherBg,
            iconColor: AppColors.roleTeacher,
            title: 'Materias',
            subtitle: '18 materias activas',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SubjectsScreen())),
          ),
          _MenuTile(
            icon: Icons.bar_chart_rounded,
            iconBg: AppColors.roleStudentBg,
            iconColor: AppColors.roleStudent,
            title: 'Reportes',
            subtitle: 'Asistencia, notas e incidencias',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
          ),
          _MenuTile(
            icon: Icons.settings_rounded,
            iconBg: const Color(0xFFF1F1F6),
            iconColor: AppColors.textSecondary,
            title: 'Configuración',
            subtitle: 'Preferencias del sistema y tu cuenta',
            onTap: () => context.go('/admin/profile'),
          ),
        ],
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
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
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
