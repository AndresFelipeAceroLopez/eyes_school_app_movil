import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/utils/validators.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/features/directory/presentation/avatar_circle.dart';
import 'package:eyes_school/core/widgets/primary_gradient_button.dart';
import 'package:eyes_school/core/widgets/simple_header_scaffold.dart';
import 'package:eyes_school/features/academic/domain/grade.dart';
import 'package:eyes_school/features/academic/domain/roster_student.dart';
import 'package:eyes_school/features/academic/domain/teacher_class.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:eyes_school/providers/session_provider.dart';
import 'package:eyes_school/features/novedades/domain/severity.dart';

/// Grade sheet for one assignment and one period.
///
/// Existing grades are loaded so the teacher edits rather than duplicates: a
/// row with a `id_nota` is a `PUT`, a row without one is a `POST`.
class GradeEntryScreen extends ConsumerStatefulWidget {
  const GradeEntryScreen({super.key, required this.assignmentId});

  final int assignmentId;

  @override
  ConsumerState<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends ConsumerState<GradeEntryScreen> {
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, String?> _errors = {};
  int? _period;
  bool _saving = false;
  int _loadedForPeriod = -1;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(int studentId) =>
      _controllers.putIfAbsent(studentId, () => TextEditingController());

  /// Seeds the inputs with what the API already has, once per period switch.
  void _seed(List<Grade> existing, int period) {
    if (_loadedForPeriod == period) return;
    _loadedForPeriod = period;
    for (final controller in _controllers.values) {
      controller.text = '';
    }
    for (final grade in existing) {
      final id = grade.studentId;
      if (id == null) continue;
      _controllerFor(id).text = grade.score.toStringAsFixed(1);
    }
  }

  Future<void> _save({
    required TeacherClass teacherClass,
    required List<RosterStudent> roster,
    required List<Grade> existing,
    required int period,
  }) async {
    final session = ref.read(currentSessionProvider);
    if (session == null) return;

    // Validate everything before writing anything: a half-saved sheet is
    // worse than a rejected one.
    final errors = <int, String?>{};
    final pending = <({int studentId, double score, int? gradeId})>[];
    final byStudent = {
      for (final g in existing)
        if (g.studentId != null) g.studentId!: g,
    };

    for (final student in roster) {
      final text = _controllers[student.id]?.text.trim() ?? '';
      if (text.isEmpty) continue;
      final error = Validators.gradeScore(text);
      if (error != null) {
        errors[student.id] = error;
        continue;
      }
      final score = Validators.parseScore(text)!;
      final current = byStudent[student.id];
      if (current != null && current.score == score) continue;
      pending.add((studentId: student.id, score: score, gradeId: current?.gradeId));
    }

    if (errors.isNotEmpty) {
      setState(() => _errors
        ..clear()
        ..addAll(errors));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Revisa las notas marcadas: deben estar entre 0.0 y 5.0.'),
      ));
      return;
    }
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cambios por guardar.')),
      );
      return;
    }

    setState(() {
      _saving = true;
      _errors.clear();
    });
    final repo = ref.read(academicRepositoryProvider);
    var saved = 0;
    String? failure;
    for (final row in pending) {
      try {
        await repo.saveGrade(
          studentId: row.studentId,
          subjectId: teacherClass.subjectId,
          period: period,
          score: row.score,
          registeredBy: session.user.userId,
          gradeId: row.gradeId,
        );
        saved++;
      } on AppFailure catch (e) {
        failure = e.message;
        break;
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);

    _loadedForPeriod = -1;
    ref.invalidate(gradeSheetProvider(
      (subjectId: teacherClass.subjectId, period: period),
    ));
    ref.invalidate(teacherDashboardProvider);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(failure == null
          ? 'Notas guardadas para $saved de ${roster.length} estudiantes.'
          : 'Se guardaron $saved. $failure'),
      backgroundColor: failure == null ? AppColors.tealDark : AppColors.pink,
    ));
    if (failure == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final classAsync = ref.watch(teacherClassProvider(widget.assignmentId));
    _period ??= ref.read(currentPeriodProvider);

    return classAsync.when(
      loading: () => const SimpleHeaderScaffold(title: 'Notas', body: LoadingView()),
      error: (error, _) => SimpleHeaderScaffold(
        title: 'Notas',
        body: ErrorView(
          error: error,
          onRetry: () => ref.invalidate(teacherClassProvider(widget.assignmentId)),
        ),
      ),
      data: (teacherClass) => teacherClass == null
          ? const SimpleHeaderScaffold(
              title: 'Notas',
              body: EmptyState(
                icon: Icons.help_outline_rounded,
                title: 'Clase no encontrada',
                message: 'Esta asignación ya no está disponible.',
              ),
            )
          : _body(teacherClass),
    );
  }

  Widget _body(TeacherClass teacherClass) {
    final period = _period!;
    final rosterAsync = ref.watch(rosterProvider(teacherClass.courseId));
    final gradesAsync = ref.watch(
      gradeSheetProvider((subjectId: teacherClass.subjectId, period: period)),
    );

    return SimpleHeaderScaffold(
      title: '${teacherClass.subjectName} · ${teacherClass.courseName}',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text('Periodo', style: AppTextStyles.caption),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: AcademicPeriods.all.map((p) {
                      final selected = p == period;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _period = p;
                              _loadedForPeriod = -1;
                            }),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.indigo : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$p',
                                style: AppTextStyles.body.copyWith(
                                  color: selected ? Colors.white : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: rosterAsync.when(
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
                return gradesAsync.when(
                  loading: () => const LoadingView(),
                  error: (error, _) => ErrorView(
                    error: error,
                    onRetry: () => ref.invalidate(gradeSheetProvider(
                      (subjectId: teacherClass.subjectId, period: period),
                    )),
                  ),
                  data: (existing) {
                    _seed(existing, period);
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                            itemCount: roster.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final student = roster[index];
                              return _GradeRow(
                                student: student,
                                controller: _controllerFor(student.id),
                                error: _errors[student.id],
                                onChanged: () {
                                  if (_errors[student.id] != null) {
                                    setState(() => _errors.remove(student.id));
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          child: PrimaryGradientButton(
                            label: 'Guardar notas',
                            loading: _saving,
                            onPressed: () => _save(
                              teacherClass: teacherClass,
                              roster: roster,
                              existing: existing,
                              period: period,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({
    required this.student,
    required this.controller,
    required this.error,
    required this.onChanged,
  });

  final RosterStudent student;
  final TextEditingController controller;
  final String? error;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, 4)),
        ],
        border: error == null ? null : Border.all(color: AppColors.pink, width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AvatarCircle(name: student.name, radius: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  student.name,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 64,
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  // The scale is 0.0–5.0, so one digit before the separator.
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,1}[.,]?\d{0,2}$')),
                  ],
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: '0.0',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    fillColor: AppColors.background,
                  ),
                ),
              ),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  error!,
                  style: AppTextStyles.caption.copyWith(color: AppColors.pink),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
