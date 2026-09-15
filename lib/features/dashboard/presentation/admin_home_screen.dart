import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/utils/formatters.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/features/directory/presentation/avatar_circle.dart';
import 'package:eyes_school/core/widgets/gradient_header.dart';
import 'package:eyes_school/core/widgets/quick_action_tile.dart';
import 'package:eyes_school/core/widgets/section_header.dart';
import 'package:eyes_school/core/widgets/stat_pill.dart';
import 'package:eyes_school/features/attendance/domain/attendance_record.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:eyes_school/providers/session_provider.dart';
import 'package:eyes_school/features/attendance/domain/attendance.dart';

/// Admin home.
///
/// The mobile admin is deliberately a hallway tool, not a control panel: the
/// API has no `/dashboard/admin` and the heavy management screens live in the
/// web panel. What this screen answers is "how is today's attendance going and
/// is anything still unsynced".
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final todayAsync = ref.watch(todayAttendanceProvider(null));
    final queue = ref.watch(attendanceQueueProvider);
    final online = ref.watch(connectivityProvider).valueOrNull ?? true;
    final catalog = ref.watch(studentCatalogProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayAttendanceProvider);
          await ref.read(attendanceRepositoryProvider).warmUp(force: true);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            GradientHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AvatarCircle(name: user?.name ?? 'Admin', radius: 26),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Administrador${user?.subject == null ? '' : ' · ${user!.subject}'}',
                              style: AppTextStyles.statLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Hola, ${user?.firstName ?? ''}',
                              style: AppTextStyles.h1
                                  .copyWith(color: Colors.white, fontSize: 22),
                            ),
                          ],
                        ),
                      ),
                      _SyncButton(
                        pending: queue.pendingCount,
                        onTap: () => context.push('/admin/qr/pendientes'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(width: 3, height: 16, color: AppColors.teal),
                      const SizedBox(width: 8),
                      Text('EYESCHOOL',
                          style: AppTextStyles.statLabel
                              .copyWith(letterSpacing: 2, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Today's counters are computed from `GET /asistencia?fecha=hoy`;
                  // there is no institutional dashboard endpoint to ask.
                  todayAsync.when(
                    loading: () => const _StatsSkeleton(),
                    error: (_, _) => Row(
                      children: [
                        StatPill(value: '${catalog.size}', label: 'Estudiantes'),
                        const SizedBox(width: 10),
                        StatPill(
                          value: '${queue.pendingCount}',
                          label: 'Por sincronizar',
                          valueColor: AppColors.pink,
                        ),
                      ],
                    ),
                    data: (rows) {
                      final entries = rows
                          .where((r) => r.kind == AttendanceKind.entry)
                          .length;
                      final late =
                          rows.where((r) => r.state == AttendanceState.late).length;
                      return Row(
                        children: [
                          StatPill(value: '${rows.length}', label: 'Registros hoy'),
                          const SizedBox(width: 10),
                          StatPill(value: '$entries', label: 'Entradas'),
                          const SizedBox(width: 10),
                          StatPill(
                            value: '$late',
                            label: 'Tardanzas',
                            valueColor: late > 0 ? AppColors.orange : AppColors.teal,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            if (!online)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: OfflineBanner(),
              ),
            if (queue.pendingCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _PendingBanner(
                  count: queue.pendingCount,
                  failed: queue.failed.length,
                  onTap: () => context.push('/admin/qr/pendientes'),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text('Acciones rápidas', style: AppTextStyles.h2),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
                children: [
                  QuickActionTile(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Escanear',
                    iconBg: AppColors.statusActiveBg,
                    iconColor: AppColors.tealDark,
                    onTap: () => context.go('/admin/qr'),
                  ),
                  QuickActionTile(
                    icon: Icons.groups_rounded,
                    label: 'Masivo',
                    iconBg: AppColors.roleTeacherBg,
                    iconColor: AppColors.roleTeacher,
                    onTap: () => context.push('/admin/masivo'),
                  ),
                  QuickActionTile(
                    icon: Icons.fact_check_rounded,
                    label: 'Registro',
                    iconBg: AppColors.roleStudentBg,
                    iconColor: AppColors.roleStudent,
                    onTap: () => context.push('/admin/dia'),
                  ),
                  QuickActionTile(
                    icon: Icons.people_alt_rounded,
                    label: 'Directorio',
                    iconBg: const Color(0xFFFCEEDD),
                    iconColor: AppColors.orange,
                    onTap: () => context.go('/admin/management'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: SectionHeader(
                title: 'Registro del día',
                trailingText: 'Ver todo',
                onTrailingTap: () => context.push('/admin/dia'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: todayAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  error: error,
                  compact: true,
                  onRetry: () => ref.invalidate(todayAttendanceProvider),
                ),
                data: (rows) {
                  if (rows.isEmpty) {
                    return const EmptyState(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Sin registros hoy',
                      message: 'Empieza a escanear para registrar la asistencia.',
                    );
                  }
                  final recent = rows.reversed.take(5).toList();
                  return SectionCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < recent.length; i++)
                          _ScanRow(
                            row: recent[i],
                            name: catalog.byId(recent[i].studentId)?.displayName,
                            showDivider: i != recent.length - 1,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Text(
                'Catálogo local: ${catalog.size} estudiantes'
                '${catalog.refreshedAt == null ? '' : ' · actualizado ${Formatters.timeAgo(catalog.refreshedAt).toLowerCase()}'}',
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncButton extends StatelessWidget {
  const _SyncButton({required this.pending, required this.onTap});

  final int pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_sync_rounded, color: Colors.white),
          ),
          if (pending > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.pink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$pending',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({
    required this.count,
    required this.failed,
    required this.onTap,
  });

  final int count;
  final int failed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasErrors = failed > 0;
    final color = hasErrors ? AppColors.pink : AppColors.blue;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(hasErrors ? Icons.error_outline_rounded : Icons.cloud_upload_rounded,
                size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasErrors
                    ? '$count registro(s) por sincronizar · $failed con error'
                    : '$count registro(s) esperando envío',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ScanRow extends StatelessWidget {
  const _ScanRow({
    required this.row,
    required this.name,
    required this.showDivider,
  });

  final AttendanceRecord row;
  final String? name;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final label = (name == null || name!.isEmpty)
        ? 'Estudiante ${row.studentId}'
        : name!;
    final color = switch (row.state) {
      AttendanceState.present => AppColors.tealDark,
      AttendanceState.late => AppColors.orange,
      AttendanceState.excused => AppColors.blue,
      _ => AppColors.pink,
    };
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  row.state.label,
                  style: AppTextStyles.caption
                      .copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.divider, indent: 16, endIndent: 16),
      ],
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (i) => Expanded(
          child: Container(
            height: 78,
            margin: EdgeInsets.only(right: i == 2 ? 0 : 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}
