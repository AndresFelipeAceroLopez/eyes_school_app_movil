import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/failures/app_failure.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_states.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/primary_gradient_button.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../domain/entities/roster_student.dart';
import '../../domain/entities/teacher_class.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/session_provider.dart';
import '../../domain/value_objects/attendance.dart';

/// Roll call for one of the teacher's assignments.
///
/// Records are written with `tipo: clase`, which is what distinguishes a
/// teacher's roll call from the gate scans an admin takes.
class ClassRosterScreen extends ConsumerStatefulWidget {
  const ClassRosterScreen({super.key, required this.assignmentId});

  final int assignmentId;

  @override
  ConsumerState<ClassRosterScreen> createState() => _ClassRosterScreenState();
}

class _ClassRosterScreenState extends ConsumerState<ClassRosterScreen> {
  final Map<int, AttendanceMark> _marks = {};
  final Map<int, String> _observations = {};
  bool _saving = false;
  int _progress = 0;

  void _ensureDefaults(List<RosterStudent> roster) {
    for (final s in roster) {
      _marks.putIfAbsent(s.id, () => AttendanceMark.present);
    }
  }

  Future<void> _save(List<RosterStudent> roster) async {
    final session = ref.read(currentSessionProvider);
    if (session == null) return;

    setState(() {
      _saving = true;
      _progress = 0;
    });
    try {
      final result = await ref.read(attendanceRepositoryProvider).recordBulk(
            marks: _marks,
            names: {for (final s in roster) s.id: s.name},
            kind: AttendanceKind.classroom,
            registeredBy: session.user.userId,
            date: DateTime.now(),
            observations: _observations,
            onProgress: (done, _) {
              if (mounted) setState(() => _progress = done);
            },
          );
      if (!mounted) return;

      final present = _marks.values.where((m) => m == AttendanceMark.present).length;
      final absent = _marks.values.where((m) => m == AttendanceMark.absent).length;
      final late = _marks.values.where((m) => m == AttendanceMark.late).length;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.duplicates > 0
            ? 'Asistencia registrada. ${result.duplicates} ya estaban tomadas hoy.'
            : 'Asistencia guardada: $present presentes, $absent ausentes, $late tardanzas.'),
        backgroundColor: AppColors.tealDark,
      ));
      ref.invalidate(teacherDashboardProvider);
      Navigator.of(context).pop();
    } on AppFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classAsync = ref.watch(teacherClassProvider(widget.assignmentId));

    return classAsync.when(
      loading: () => const SimpleHeaderScaffold(title: 'Asistencia', body: LoadingView()),
      error: (error, _) => SimpleHeaderScaffold(
        title: 'Asistencia',
        body: ErrorView(
          error: error,
          onRetry: () => ref.invalidate(teacherClassProvider(widget.assignmentId)),
        ),
      ),
      data: (teacherClass) {
        if (teacherClass == null) {
          return const SimpleHeaderScaffold(
            title: 'Asistencia',
            body: EmptyState(
              icon: Icons.help_outline_rounded,
              title: 'Clase no encontrada',
              message: 'Esta asignación ya no está disponible.',
            ),
          );
        }
        return _body(teacherClass);
      },
    );
  }

  Widget _body(TeacherClass teacherClass) {
    final rosterAsync = ref.watch(rosterProvider(teacherClass.courseId));

    return SimpleHeaderScaffold(
      title: '${teacherClass.subjectName} · ${teacherClass.courseName}',
      body: rosterAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(rosterProvider(teacherClass.courseId)),
        ),
        data: (roster) {
          if (roster.isEmpty) {
            return const EmptyState(
              icon: Icons.person_off_rounded,
              title: 'Curso sin estudiantes',
              message: 'Este curso no tiene estudiantes activos matriculados.',
            );
          }
          _ensureDefaults(roster);
          final present = _marks.values.where((m) => m == AttendanceMark.present).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(Formatters.todayLong(DateTime.now()),
                              style: AppTextStyles.h3),
                          Text('$present de ${roster.length} presentes',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        for (final s in roster) {
                          _marks[s.id] = AttendanceMark.present;
                        }
                      }),
                      child: Text('Todos presentes', style: AppTextStyles.link),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  itemCount: roster.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final student = roster[index];
                    return _RosterRow(
                      student: student,
                      mark: _marks[student.id]!,
                      observation: _observations[student.id],
                      onChanged: (mark) => setState(() => _marks[student.id] = mark),
                      onObservation: (text) => setState(() {
                        if (text == null || text.isEmpty) {
                          _observations.remove(student.id);
                        } else {
                          _observations[student.id] = text;
                        }
                      }),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    if (_saving && _progress > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text('$_progress/${_marks.length} enviados',
                            style: AppTextStyles.caption),
                      ),
                    PrimaryGradientButton(
                      label: 'Guardar asistencia',
                      loading: _saving,
                      onPressed: () => _save(roster),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({
    required this.student,
    required this.mark,
    required this.observation,
    required this.onChanged,
    required this.onObservation,
  });

  final RosterStudent student;
  final AttendanceMark mark;
  final String? observation;
  final ValueChanged<AttendanceMark> onChanged;
  final ValueChanged<String?> onObservation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              AvatarCircle(name: student.name, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (student.code != null)
                      Text(student.code!, style: AppTextStyles.caption),
                  ],
                ),
              ),
              _MarkButton(
                icon: Icons.check_rounded,
                color: AppColors.tealDark,
                selected: mark == AttendanceMark.present,
                onTap: () => onChanged(AttendanceMark.present),
              ),
              const SizedBox(width: 6),
              _MarkButton(
                icon: Icons.schedule_rounded,
                color: AppColors.orange,
                selected: mark == AttendanceMark.late,
                onTap: () => onChanged(AttendanceMark.late),
              ),
              const SizedBox(width: 6),
              _MarkButton(
                icon: Icons.close_rounded,
                color: AppColors.pink,
                selected: mark == AttendanceMark.absent,
                onTap: () => onChanged(AttendanceMark.absent),
              ),
              const SizedBox(width: 6),
              _MarkButton(
                icon: Icons.assignment_turned_in_outlined,
                color: AppColors.blue,
                selected: mark == AttendanceMark.excused,
                onTap: () => onChanged(AttendanceMark.excused),
              ),
            ],
          ),
          if (mark != AttendanceMark.present) ...[
            const SizedBox(height: 8),
            TextFormField(
              initialValue: observation,
              onChanged: onObservation,
              style: AppTextStyles.caption,
              decoration: const InputDecoration(
                hintText: 'Observación (opcional)',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MarkButton extends StatelessWidget {
  const _MarkButton({
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: selected ? color : AppColors.background,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: selected ? Colors.white : AppColors.textSecondary),
      ),
    );
  }
}
