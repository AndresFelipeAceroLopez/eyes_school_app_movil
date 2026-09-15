import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/utils/formatters.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/features/directory/presentation/avatar_circle.dart';
import 'package:eyes_school/core/widgets/section_header.dart';
import 'package:eyes_school/core/widgets/simple_header_scaffold.dart';
import 'package:eyes_school/features/attendance/domain/attendance_record.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:eyes_school/features/attendance/domain/attendance.dart';

/// "Registro del día": everything the API already has for today.
///
/// `GET /asistencia` filters by date server-side but not by course or shift
/// (backend gap #9), so those two filters are applied here on the result.
class TodayAttendanceScreen extends ConsumerStatefulWidget {
  const TodayAttendanceScreen({super.key});

  @override
  ConsumerState<TodayAttendanceScreen> createState() => _TodayAttendanceScreenState();
}

class _TodayAttendanceScreenState extends ConsumerState<TodayAttendanceScreen> {
  AttendanceKind? _tipo;
  int? _courseId;

  @override
  Widget build(BuildContext context) {
    final rowsAsync = ref.watch(todayAttendanceProvider(_tipo));
    final coursesAsync = ref.watch(coursesProvider);
    final catalog = ref.watch(studentCatalogProvider);

    return SimpleHeaderScaffold(
      title: 'Registro del día',
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
          onPressed: () => _openFilters(context),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(todayAttendanceProvider),
        child: rowsAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => ListView(children: [
            ErrorView(
              error: error,
              onRetry: () => ref.invalidate(todayAttendanceProvider),
            ),
          ]),
          data: (rows) {
            final filtered = _courseId == null
                ? rows
                : rows
                    .where((r) => catalog.byId(r.studentId)?.courseId == _courseId)
                    .toList()
              ..sort((a, b) =>
                  (b.registeredAt ?? b.date).compareTo(a.registeredAt ?? a.date));

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                SectionCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${filtered.length}',
                                style: AppTextStyles.statValue
                                    .copyWith(color: AppColors.indigo)),
                            Text(
                              Formatters.todayLong(DateTime.now()),
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      if (_tipo != null || _courseId != null)
                        TextButton(
                          onPressed: () => setState(() {
                            _tipo = null;
                            _courseId = null;
                          }),
                          child: Text('Quitar filtros', style: AppTextStyles.link),
                        ),
                    ],
                  ),
                ),
                if (_activeFilters(coursesAsync.valueOrNull).isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: _activeFilters(coursesAsync.valueOrNull)
                        .map((label) => Chip(
                              label: Text(label, style: AppTextStyles.caption),
                              backgroundColor: AppColors.roleStudentBg,
                              side: BorderSide.none,
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 20),
                if (filtered.isEmpty)
                  const EmptyState(
                    icon: Icons.event_busy_rounded,
                    title: 'Sin registros hoy',
                    message: 'Los escaneos aparecerán aquí en cuanto se sincronicen.',
                  )
                else
                  for (final row in filtered)
                    _AttendanceRow(
                      row: row,
                      name: catalog.byId(row.studentId)?.displayName,
                      onUndo: () => _undo(row),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<String> _activeFilters(List<dynamic>? courses) {
    final labels = <String>[];
    if (_tipo != null) labels.add(_tipo!.label);
    if (_courseId != null) {
      final course = courses?.where((c) => c.id == _courseId).firstOrNull;
      labels.add(course?.name as String? ?? 'Curso $_courseId');
    }
    return labels;
  }

  Future<void> _openFilters(BuildContext context) async {
    final courses = ref.read(coursesProvider).valueOrNull ?? const [];
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('Filtros', style: AppTextStyles.h2),
              const SizedBox(height: 18),
              Text('Tipo', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _chip('Todos', _tipo == null, () {
                    setState(() => _tipo = null);
                    setSheetState(() {});
                  }),
                  for (final t in AttendanceKind.values)
                    _chip(t.label, _tipo == t, () {
                      setState(() => _tipo = t);
                      setSheetState(() {});
                    }),
                ],
              ),
              const SizedBox(height: 20),
              Text('Curso', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('Todos', _courseId == null, () {
                    setState(() => _courseId = null);
                    setSheetState(() {});
                  }),
                  for (final course in courses)
                    _chip(course.name, _courseId == course.id, () {
                      setState(() => _courseId = course.id);
                      setSheetState(() {});
                    }),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Listo', style: AppTextStyles.link),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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

  /// Undoing a scan is destructive, so it always asks first.
  Future<void> _undo(AttendanceRecord row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Eliminar registro', style: AppTextStyles.h3),
        content: Text(
          'Se eliminará del servidor el registro de asistencia seleccionado.',
          style: AppTextStyles.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Eliminar',
                style: AppTextStyles.link.copyWith(color: AppColors.pink)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(attendanceRepositoryProvider).undo(row.id);
      ref.invalidate(todayAttendanceProvider);
    } on AppFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.row, required this.name, required this.onUndo});

  final AttendanceRecord row;
  final String? name;
  final VoidCallback onUndo;

  Color get _stateColor => switch (row.state) {
        AttendanceState.present => AppColors.tealDark,
        AttendanceState.late => AppColors.orange,
        AttendanceState.excused => AppColors.blue,
        _ => AppColors.pink,
      };

  @override
  Widget build(BuildContext context) {
    final label = (name == null || name!.isEmpty)
        ? 'Estudiante ${row.studentId}'
        : name!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            AvatarCircle(name: label, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    [
                      row.kind?.label,
                      if (row.registeredAt != null)
                        TimeOfDay.fromDateTime(row.registeredAt!).format(context),
                    ].whereType<String>().join(' · '),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _stateColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                row.state.label,
                style: AppTextStyles.caption
                    .copyWith(color: _stateColor, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Deshacer',
              onPressed: onUndo,
              icon: const Icon(Icons.undo_rounded, size: 18, color: AppColors.textSecondary),
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
