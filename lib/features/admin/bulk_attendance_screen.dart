import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/failures/app_failure.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_states.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/primary_gradient_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/entities/roster_student.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/session_provider.dart';
import '../../domain/value_objects/attendance.dart';

/// Bulk attendance for a whole course: shift → course → date → type → list.
///
/// Everyone starts marked Presente because that is the common case; the user
/// only touches the exceptions. Sending queues every row first, so the work is
/// safe even if the network dies halfway.
class BulkAttendanceScreen extends ConsumerStatefulWidget {
  const BulkAttendanceScreen({super.key});

  @override
  ConsumerState<BulkAttendanceScreen> createState() => _BulkAttendanceScreenState();
}

class _BulkAttendanceScreenState extends ConsumerState<BulkAttendanceScreen> {
  String? _shift;
  Course? _course;
  DateTime _date = DateTime.now();
  AttendanceKind _tipo = AttendanceKind.entry;

  final Map<int, AttendanceMark> _marks = {};
  bool _sending = false;
  int _progress = 0;

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);

    return SimpleHeaderScaffold(
      title: 'Registro masivo',
      body: coursesAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(coursesProvider),
        ),
        data: (courses) {
          final visible = _shift == null
              ? courses
              : courses.where((c) => c.shiftLabel == _shift).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              _stepCard(
                step: 1,
                title: 'Jornada',
                child: Wrap(
                  spacing: 8,
                  children: [
                    _chip('Todas', _shift == null, () => setState(() {
                          _shift = null;
                          _course = null;
                        })),
                    for (final shift in const ['Mañana', 'Tarde', 'Única'])
                      _chip(shift, _shift == shift, () => setState(() {
                            _shift = shift;
                            _course = null;
                          })),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _stepCard(
                step: 2,
                title: 'Curso',
                child: DropdownButtonFormField<int>(
                  initialValue: _course?.id,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.class_outlined),
                    hintText: 'Selecciona un curso',
                  ),
                  items: visible
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.name} · ${c.shiftLabel}'),
                          ))
                      .toList(),
                  onChanged: (id) => setState(() {
                    _course = visible.where((c) => c.id == id).firstOrNull;
                    _marks.clear();
                  }),
                ),
              ),
              const SizedBox(height: 14),
              _stepCard(
                step: 3,
                title: 'Fecha y tipo',
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_rounded,
                                size: 20, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Text(Formatters.todayLong(_date), style: AppTextStyles.body),
                            const Spacer(),
                            const Icon(Icons.expand_more_rounded,
                                color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (final option in AttendanceKind.values)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _chip(
                                option.label,
                                _tipo == option,
                                () => setState(() => _tipo = option),
                                fullWidth: true,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_course == null)
                const EmptyState(
                  icon: Icons.groups_rounded,
                  title: 'Selecciona un curso',
                  message: 'Elige el curso para cargar su lista de estudiantes.',
                )
              else
                _RosterSection(
                  courseId: _course!.id,
                  marks: _marks,
                  onChanged: (id, mark) => setState(() => _marks[id] = mark),
                  onSeeded: (roster) {
                    for (final s in roster) {
                      _marks.putIfAbsent(s.id, () => AttendanceMark.present);
                    }
                  },
                  onMarkAll: (roster, mark) => setState(() {
                    for (final s in roster) {
                      _marks[s.id] = mark;
                    }
                  }),
                  sending: _sending,
                  progress: _progress,
                  onSubmit: _submit,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _stepCard({required int step, required String title, required Widget child}) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.primaryGradient),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$step',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, {bool fullWidth = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        alignment: fullWidth ? Alignment.center : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.indigo : AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      helpText: 'Fecha del registro',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit(List<RosterStudent> roster) async {
    final session = ref.read(currentSessionProvider);
    if (session == null || _marks.isEmpty) return;

    setState(() {
      _sending = true;
      _progress = 0;
    });
    try {
      final result = await ref.read(attendanceRepositoryProvider).recordBulk(
            marks: _marks,
            names: {for (final s in roster) s.id: s.name},
            kind: _tipo,
            registeredBy: session.user.userId,
            date: _date,
            onProgress: (done, total) {
              if (mounted) setState(() => _progress = done);
            },
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.duplicates == 0
            ? '${result.queued} registro(s) enviados.'
            : '${result.queued} enviados · ${result.duplicates} ya existían.'),
        backgroundColor: AppColors.tealDark,
      ));
      ref.invalidate(todayAttendanceProvider);
    } on AppFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _RosterSection extends ConsumerWidget {
  const _RosterSection({
    required this.courseId,
    required this.marks,
    required this.onChanged,
    required this.onSeeded,
    required this.onMarkAll,
    required this.sending,
    required this.progress,
    required this.onSubmit,
  });

  final int courseId;
  final Map<int, AttendanceMark> marks;
  final void Function(int studentId, AttendanceMark mark) onChanged;
  final void Function(List<RosterStudent> roster) onSeeded;
  final void Function(List<RosterStudent> roster, AttendanceMark mark) onMarkAll;
  final bool sending;
  final int progress;
  final Future<void> Function(List<RosterStudent> roster) onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(rosterProvider(courseId));

    return rosterAsync.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(rosterProvider(courseId)),
      ),
      data: (roster) {
        if (roster.isEmpty) {
          return const EmptyState(
            icon: Icons.person_off_rounded,
            title: 'Curso sin estudiantes',
            message: 'Este curso no tiene estudiantes activos matriculados.',
          );
        }
        onSeeded(roster);
        final present =
            marks.values.where((m) => m == AttendanceMark.present).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Lista (${roster.length})',
              trailingText: 'Todos presentes',
              onTrailingTap: () => onMarkAll(roster, AttendanceMark.present),
            ),
            const SizedBox(height: 6),
            Text('$present de ${roster.length} marcados presentes',
                style: AppTextStyles.caption),
            const SizedBox(height: 14),
            for (final student in roster)
              _RosterRow(
                student: student,
                mark: marks[student.id] ?? AttendanceMark.present,
                onChanged: (mark) => onChanged(student.id, mark),
              ),
            const SizedBox(height: 12),
            if (sending && progress > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$progress/${marks.length} enviados',
                        style: AppTextStyles.caption),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: marks.isEmpty ? 0 : progress / marks.length,
                        minHeight: 6,
                        backgroundColor: AppColors.divider,
                        valueColor: const AlwaysStoppedAnimation(AppColors.indigo),
                      ),
                    ),
                  ],
                ),
              ),
            PrimaryGradientButton(
              label: 'Enviar registro',
              icon: Icons.send_rounded,
              loading: sending,
              onPressed: () => onSubmit(roster),
            ),
          ],
        );
      },
    );
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({
    required this.student,
    required this.mark,
    required this.onChanged,
  });

  final RosterStudent student;
  final AttendanceMark mark;
  final ValueChanged<AttendanceMark> onChanged;

  static const _options = [
    AttendanceMark.present,
    AttendanceMark.late,
    AttendanceMark.absent,
    AttendanceMark.excused,
  ];

  static Color colorFor(AttendanceMark mark) => switch (mark) {
        AttendanceMark.present => AppColors.tealDark,
        AttendanceMark.late => AppColors.orange,
        AttendanceMark.absent => AppColors.pink,
        AttendanceMark.excused => AppColors.blue,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarCircle(name: student.name, radius: 18),
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
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: _options.map((option) {
                final selected = mark == option;
                final color = colorFor(option);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => onChanged(option),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? color : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          option.label,
                          style: AppTextStyles.caption.copyWith(
                            color: selected ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
