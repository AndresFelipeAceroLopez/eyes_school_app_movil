import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/report_card_download.dart';
import '../../core/widgets/async_states.dart';
import '../../core/widgets/attendance_donut.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/grade_row.dart';
import '../../core/widgets/novedad_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../core/widgets/status_badge.dart';
import '../../domain/entities/app_user.dart';
import '../../providers/data_providers.dart';
import '../../providers/session_provider.dart';
import '../../domain/value_objects/severity.dart';

/// The 360° student card: identity, guardians, grades, attendance and news.
///
/// Reached from the admin directory, from a teacher's class list and from a
/// guardian's home. No single endpoint carries all of it, so the repository
/// assembles it and this screen only paints.
class StudentProfileScreen extends ConsumerStatefulWidget {
  const StudentProfileScreen({super.key, required this.studentId});

  final int studentId;

  @override
  ConsumerState<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(studentProfileProvider(widget.studentId));

    return SimpleHeaderScaffold(
      title: 'Estudiante',
      actions: [
        IconButton(
          tooltip: 'Boletín PDF',
          icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
          onPressed: () => ReportCardDownloader.run(
            context,
            ref,
            studentId: widget.studentId,
            studentName: profileAsync.valueOrNull?.name ?? 'estudiante',
          ),
        ),
      ],
      body: profileAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(studentProfileProvider(widget.studentId)),
        ),
        data: (student) {
          if (student == null) {
            return const EmptyState(
              icon: Icons.person_search_rounded,
              title: 'Estudiante no encontrado',
              message: 'Esta ficha ya no está disponible.',
            );
          }
          return Column(
            children: [
              _Header(student: student, onShowQr: () => _showQr(student)),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.indigo,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.indigo,
                labelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'Notas'),
                  Tab(text: 'Asistencia'),
                  Tab(text: 'Novedades'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _GradesTab(studentId: widget.studentId),
                    _AttendanceTab(studentId: widget.studentId),
                    _NovedadesTab(studentId: widget.studentId),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The same code the web panel encodes, full screen so a scanner can read it
  /// off this device when the student forgot their card.
  void _showQr(AppUser student) {
    final code = student.code;
    if (code == null || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este estudiante no tiene código asignado.')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: code,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.textPrimary,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              Text(student.name, style: AppTextStyles.h3, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(code, style: AppTextStyles.bodyMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.student, required this.onShowQr});

  final AppUser student;
  final VoidCallback onShowQr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: SectionCard(
        child: Column(
          children: [
            Row(
              children: [
                AvatarCircle(name: student.name, radius: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.name,
                          style: AppTextStyles.h3,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        [student.code, student.grade, student.jornada]
                            .whereType<String>()
                            .join(' · '),
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 8),
                      StatusBadge(active: student.isActive),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Ver QR',
                  onPressed: onShowQr,
                  icon: const Icon(Icons.qr_code_2_rounded,
                      color: AppColors.indigo, size: 28),
                ),
              ],
            ),
            if (student.phone != null || student.document != null) ...[
              const Divider(height: 24, color: AppColors.divider),
              Row(
                children: [
                  if (student.document != null)
                    Expanded(
                      child: _Fact(
                          icon: Icons.badge_outlined,
                          label: 'Documento',
                          value: student.document!),
                    ),
                  if (student.phone != null)
                    Expanded(
                      child: _Fact(
                          icon: Icons.phone_outlined,
                          label: 'Teléfono',
                          value: student.phone!),
                    ),
                ],
              ),
            ],
            if (student.guardians.isNotEmpty) ...[
              const Divider(height: 24, color: AppColors.divider),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Acudientes', style: AppTextStyles.caption),
              ),
              const SizedBox(height: 8),
              for (final guardian in student.guardians)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.diversity_3_rounded,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${guardian.name} · ${guardian.relation}',
                          style: AppTextStyles.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(guardian.phone, style: AppTextStyles.caption),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(value,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _GradesTab extends ConsumerStatefulWidget {
  const _GradesTab({required this.studentId});

  final int studentId;

  @override
  ConsumerState<_GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends ConsumerState<_GradesTab> {
  int? _period;

  @override
  Widget build(BuildContext context) {
    _period ??= ref.read(currentPeriodProvider);
    final args = (studentId: widget.studentId, period: _period);
    final gradesAsync = ref.watch(gradesForStudentProvider(args));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(gradesForStudentProvider(args)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          PeriodSelector(
            periods: AcademicPeriods.all,
            selected: _period!,
            onChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(height: 18),
          gradesAsync.when(
            loading: () => const LoadingView(),
            error: (error, _) => ErrorView(
              error: error,
              onRetry: () => ref.invalidate(gradesForStudentProvider(args)),
            ),
            data: (grades) {
              if (grades.isEmpty) {
                return EmptyState(
                  icon: Icons.bar_chart_rounded,
                  title: 'Sin notas',
                  message: 'No hay notas registradas en el periodo ${_period!}.',
                );
              }
              final average = GradesCard.overallAverage(grades);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Promedio', style: AppTextStyles.caption),
                              Text(
                                average.toStringAsFixed(1),
                                style: AppTextStyles.h1.copyWith(
                                  color: average >= 3.0
                                      ? AppColors.tealDark
                                      : AppColors.pink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(AcademicPeriods.labelOf(_period!),
                            style: AppTextStyles.bodyMuted),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GradesCard(grades: grades),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AttendanceTab extends ConsumerWidget {
  const _AttendanceTab({required this.studentId});

  final int studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(attendanceSummaryProvider(studentId));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(attendanceSummaryProvider(studentId)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          summaryAsync.when(
            loading: () => const LoadingView(),
            error: (error, _) => ErrorView(
              error: error,
              onRetry: () => ref.invalidate(attendanceSummaryProvider(studentId)),
            ),
            data: (summary) {
              if (summary.total == 0) {
                return const EmptyState(
                  icon: Icons.fact_check_outlined,
                  title: 'Sin registros',
                  message: 'Todavía no hay asistencia registrada.',
                );
              }
              return SectionCard(
                child: Column(
                  children: [
                    AttendanceDonut(percent: summary.percent),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _Metric(
                            label: 'Presente',
                            value: summary.present,
                            color: AppColors.tealDark),
                        _Metric(
                            label: 'Tarde', value: summary.late, color: AppColors.orange),
                        _Metric(
                            label: 'Ausente',
                            value: summary.absent,
                            color: AppColors.pink),
                        _Metric(
                            label: 'Excusa',
                            value: summary.excused,
                            color: AppColors.blue),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Sobre los últimos ${summary.total} registros',
                        style: AppTextStyles.caption),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: AppTextStyles.h3.copyWith(color: color)),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _NovedadesTab extends ConsumerWidget {
  const _NovedadesTab({required this.studentId});

  final int studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novedadesAsync = ref.watch(novedadesForStudentProvider(studentId));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(novedadesForStudentProvider(studentId)),
      child: novedadesAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ListView(children: [
          ErrorView(
            error: error,
            onRetry: () => ref.invalidate(novedadesForStudentProvider(studentId)),
          ),
        ]),
        data: (novedades) {
          if (novedades.isEmpty) {
            return ListView(children: const [
              EmptyState(
                icon: Icons.check_circle_outline_rounded,
                title: 'Sin novedades',
                message: 'Este estudiante no tiene novedades registradas.',
              ),
            ]);
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: novedades.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                NovedadCard(novedad: novedades[index], showStudent: false),
          );
        },
      ),
    );
  }
}
