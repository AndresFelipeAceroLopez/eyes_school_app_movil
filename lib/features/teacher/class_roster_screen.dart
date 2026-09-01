import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/primary_gradient_button.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../models/roster_student.dart';
import '../../providers/data_providers.dart';

/// Attendance-taking screen for a single class/group. Marks are held in
/// local state only (there's no backend to persist to yet) — saving shows
/// a confirmation summary, matching the rest of this prototype's data layer.
class ClassRosterScreen extends ConsumerStatefulWidget {
  const ClassRosterScreen({super.key, required this.group, required this.subject});

  final String group;
  final String subject;

  @override
  ConsumerState<ClassRosterScreen> createState() => _ClassRosterScreenState();
}

class _ClassRosterScreenState extends ConsumerState<ClassRosterScreen> {
  final Map<String, AttendanceMark> _marks = {};
  bool _saving = false;

  void _ensureDefaults(List<RosterStudent> roster) {
    for (final s in roster) {
      _marks.putIfAbsent(s.id, () => AttendanceMark.present);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _saving = false);
    final present = _marks.values.where((m) => m == AttendanceMark.present).length;
    final absent = _marks.values.where((m) => m == AttendanceMark.absent).length;
    final late = _marks.values.where((m) => m == AttendanceMark.late).length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Asistencia guardada: $present presentes, $absent ausentes, $late tardanzas.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(rosterForGroupProvider(widget.group));

    return SimpleHeaderScaffold(
      title: '${widget.subject} · ${widget.group}',
      body: rosterAsync.when(
        data: (roster) {
          _ensureDefaults(roster);
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  itemCount: roster.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final student = roster[index];
                    return _RosterRow(
                      student: student,
                      mark: _marks[student.id]!,
                      onChanged: (mark) => setState(() => _marks[student.id] = mark),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: PrimaryGradientButton(
                  label: 'Guardar asistencia',
                  loading: _saving,
                  onPressed: _save,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text('No se pudo cargar el listado.', style: AppTextStyles.bodyMuted)),
      ),
    );
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({required this.student, required this.mark, required this.onChanged});

  final RosterStudent student;
  final AttendanceMark mark;
  final ValueChanged<AttendanceMark> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          AvatarCircle(name: student.name, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(student.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
          ),
          _MarkButton(
            icon: Icons.check_rounded,
            color: AppColors.tealDark,
            selected: mark == AttendanceMark.present,
            onTap: () => onChanged(AttendanceMark.present),
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
            icon: Icons.schedule_rounded,
            color: AppColors.orange,
            selected: mark == AttendanceMark.late,
            onTap: () => onChanged(AttendanceMark.late),
          ),
        ],
      ),
    );
  }
}

class _MarkButton extends StatelessWidget {
  const _MarkButton({required this.icon, required this.color, required this.selected, required this.onTap});

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
