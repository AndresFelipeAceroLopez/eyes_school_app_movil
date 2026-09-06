import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_config.dart';
import '../../domain/failures/app_failure.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_states.dart';
import '../../core/widgets/attendance_donut.dart';
import '../../core/widgets/section_header.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_summary.dart';
import '../../providers/repository_providers.dart';
import '../../domain/value_objects/attendance.dart';

/// Paginated attendance history for one student, shared by the student and
/// guardian tabs.
///
/// The API exposes `skip`/`limit` with no totals, so there is no page counter:
/// the only signal that more exists is `page.length == limit`, which is what
/// infinite scroll needs anyway.
class AttendanceHistoryView extends ConsumerStatefulWidget {
  const AttendanceHistoryView({
    super.key,
    required this.studentId,
    this.header,
  });

  final int studentId;

  /// Optional card rendered above the summary (used by the guardian tab to
  /// show which child the list is about).
  final Widget? header;

  @override
  ConsumerState<AttendanceHistoryView> createState() => _AttendanceHistoryViewState();
}

class _AttendanceHistoryViewState extends ConsumerState<AttendanceHistoryView> {
  final _scrollController = ScrollController();
  final List<AttendanceRecord> _rows = [];

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void didUpdateWidget(AttendanceHistoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId != widget.studentId) _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) _loadMore();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
      _rows.clear();
      _hasMore = true;
    });
    try {
      final page = await ref
          .read(academicRepositoryProvider)
          .attendanceHistory(widget.studentId, limit: ApiConfig.pageSize);
      if (!mounted) return;
      setState(() {
        _rows.addAll(page);
        _hasMore = page.length == ApiConfig.pageSize;
        _loading = false;
      });
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref.read(academicRepositoryProvider).attendanceHistory(
            widget.studentId,
            skip: _rows.length,
            limit: ApiConfig.pageSize,
          );
      if (!mounted) return;
      setState(() {
        _rows.addAll(page);
        _hasMore = page.length == ApiConfig.pageSize;
        _loadingMore = false;
      });
    } on AppFailure {
      // A failed page is not a failed screen: stop paging and keep what loaded.
      if (mounted) {
        setState(() {
          _loadingMore = false;
          _hasMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null && _rows.isEmpty) {
      return ErrorView(error: _error!, onRetry: _loadFirstPage);
    }

    if (_rows.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFirstPage,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            if (widget.header != null) widget.header!,
            const EmptyState(
              icon: Icons.fact_check_outlined,
              title: 'Sin registros',
              message: 'Todavía no hay asistencia registrada.',
            ),
          ],
        ),
      );
    }

    final summary = AttendanceSummary.of(_rows);

    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        // header + summary + rows (+ trailing loader)
        itemCount: _rows.length + 2 + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return widget.header ?? const SizedBox.shrink();
          }
          if (index == 1) {
            return Padding(
              padding: EdgeInsets.only(top: widget.header == null ? 0 : 16, bottom: 20),
              child: _SummaryCard(summary: summary, sample: _rows.length),
            );
          }
          final rowIndex = index - 2;
          if (rowIndex >= _rows.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            );
          }
          return _AttendanceTile(row: _rows[rowIndex]);
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.sample});

  final AttendanceSummary summary;
  final int sample;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          AttendanceDonut(percent: summary.percent, size: 92),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Asistencia', style: AppTextStyles.h3),
                Text('Sobre los últimos $sample registros',
                    style: AppTextStyles.caption),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _Legend(
                        color: AppColors.tealDark,
                        label: 'Presente',
                        value: summary.present),
                    _Legend(
                        color: AppColors.orange, label: 'Tarde', value: summary.late),
                    _Legend(
                        color: AppColors.pink, label: 'Ausente', value: summary.absent),
                    _Legend(
                        color: AppColors.blue, label: 'Excusa', value: summary.excused),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label · $value', style: AppTextStyles.caption),
      ],
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({required this.row});

  final AttendanceRecord row;

  Color get _color => switch (row.state) {
        AttendanceState.present => AppColors.tealDark,
        AttendanceState.late => AppColors.orange,
        AttendanceState.excused => AppColors.blue,
        _ => AppColors.pink,
      };

  IconData get _icon => switch (row.state) {
        AttendanceState.present => Icons.check_rounded,
        AttendanceState.late => Icons.schedule_rounded,
        AttendanceState.excused => Icons.assignment_turned_in_outlined,
        _ => Icons.close_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, size: 20, color: _color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.todayLong(row.date),
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    [row.kind?.label, row.observation]
                        .whereType<String>()
                        .join(' · '),
                    style: AppTextStyles.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                row.state.label,
                style: AppTextStyles.caption
                    .copyWith(color: _color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
