import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../data/mock/mock_seed.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      (
        icon: Icons.fact_check_rounded,
        color: AppColors.tealDark,
        bg: AppColors.statusActiveBg,
        title: 'Asistencia',
        subtitle: '${MockSeed.adminAttendanceToday.percent}% de asistencia hoy',
      ),
      (
        icon: Icons.bar_chart_rounded,
        color: AppColors.roleTeacher,
        bg: AppColors.roleTeacherBg,
        title: 'Notas',
        subtitle: '${MockSeed.adminGradesRegistered} notas registradas este período',
      ),
      (
        icon: Icons.warning_amber_rounded,
        color: AppColors.orange,
        bg: const Color(0xFFFCEEDD),
        title: 'Incidencias',
        subtitle: '${MockSeed.adminIncidents} novedades · ${MockSeed.adminIncidentsUnresolved} sin resolver',
      ),
      (
        icon: Icons.people_alt_rounded,
        color: AppColors.roleStudent,
        bg: AppColors.roleStudentBg,
        title: 'Usuarios',
        subtitle: '${MockSeed.adminStudentCount} estudiantes · ${MockSeed.adminTeacherCount} docentes',
      ),
    ];

    return SimpleHeaderScaffold(
      title: 'Reportes',
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        itemCount: reports.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final r = reports[index];
          return SectionCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: r.bg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(r.icon, color: r.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.title, style: AppTextStyles.h3),
                      Text(r.subtitle, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reporte de ${r.title.toLowerCase()} generado.')),
                  ),
                  child: const Text('Generar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
