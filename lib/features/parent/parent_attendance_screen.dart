import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../models/user.dart';
import '../../providers/data_providers.dart';
import '../../providers/session_provider.dart';
import 'child_selector.dart';

class ParentAttendanceScreen extends ConsumerStatefulWidget {
  const ParentAttendanceScreen({super.key});

  @override
  ConsumerState<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends ConsumerState<ParentAttendanceScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider).value;
    if (user == null) return const SizedBox.shrink();
    final childrenAsync = ref.watch(childrenOfProvider(user));

    return SimpleHeaderScaffold(
      title: 'Asistencia',
      showBack: false,
      body: childrenAsync.when(
        data: (children) {
          if (children.isEmpty) {
            return Center(child: Text('No tienes hijos vinculados.', style: AppTextStyles.bodyMuted));
          }
          final selected = children.firstWhere(
            (c) => c.id == _selectedId,
            orElse: () => children.first,
          );
          return Column(
            children: [
              ChildSelector(
                children: children,
                selectedId: selected.id,
                onSelected: (id) => setState(() => _selectedId = id),
              ),
              Expanded(child: _AttendanceBody(student: selected)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text('No se pudo cargar la información.', style: AppTextStyles.bodyMuted)),
      ),
    );
  }
}

class _AttendanceBody extends ConsumerWidget {
  const _AttendanceBody({required this.student});
  final AppUser student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceForStudentProvider(student.id));
    return attendanceAsync.when(
      data: (attendance) {
        if (attendance == null) {
          return Center(child: Text('Sin datos de asistencia.', style: AppTextStyles.bodyMuted));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            SectionCard(
              child: Column(
                children: [
                  Text('${attendance.percent}%',
                      style: AppTextStyles.h1.copyWith(color: AppColors.tealDark, fontSize: 34)),
                  Text('Asistencia general de ${student.firstName}', style: AppTextStyles.bodyMuted),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                          child: _Stat(label: 'Presentes', value: '${attendance.present}', color: AppColors.tealDark)),
                      Expanded(
                          child: _Stat(label: 'Ausentes', value: '${attendance.absent}', color: AppColors.pink)),
                      Expanded(
                          child: _Stat(label: 'Tardanzas', value: '${attendance.late}', color: AppColors.orange)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text('No se pudo cargar la asistencia.', style: AppTextStyles.bodyMuted)),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h2.copyWith(color: color)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
