import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/grade.dart';
import '../../models/novedad.dart';
import '../../models/user.dart';
import '../../providers/data_providers.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(studentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: userAsync.when(
        data: (student) {
          if (student == null) {
            return const Center(child: Text('Estudiante no encontrado.'));
          }
          return _StudentProfileBody(student: student);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('No se pudo cargar el perfil.')),
      ),
    );
  }
}

class _StudentProfileBody extends ConsumerWidget {
  const _StudentProfileBody({required this.student});
  final AppUser student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 8, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.headerGradient,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Text('Perfil del estudiante',
                            style: AppTextStyles.h3.copyWith(color: Colors.white),
                            textAlign: TextAlign.center),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AvatarCircle(name: student.name, radius: 44),
                  const SizedBox(height: 14),
                  Text(student.name, style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 22)),
                  const SizedBox(height: 4),
                  Text('${student.grade} · ${student.jornada}', style: AppTextStyles.statLabel),
                  const SizedBox(height: 10),
                  StatusBadge(active: student.status.isActive),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _HeaderStat(value: '${student.average}', label: 'Promedio'),
                      _HeaderStat(
                          value: '${student.attendancePercent?.round()}%',
                          label: 'Asistencia',
                          valueColor: AppColors.indigo),
                      _HeaderStat(
                          value: '${ref.watch(novedadesForStudentProvider(student.id)).value?.length ?? 0}',
                          label: 'Novedades',
                          valueColor: AppColors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              const TabBar(
                labelColor: AppColors.indigo,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.indigo,
                labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                tabs: [
                  Tab(text: 'Resumen'),
                  Tab(text: 'Notas'),
                  Tab(text: 'Asistencia'),
                  Tab(text: 'Novedades'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _ResumenTab(student: student),
            _NotasTab(studentId: student.id),
            _AsistenciaTab(studentId: student.id),
            _NovedadesTab(studentId: student.id),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.value, required this.label, this.valueColor = AppColors.teal});
  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.h1.copyWith(color: valueColor, fontSize: 22)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.statLabel),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(color: AppColors.surface, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

class _ResumenTab extends StatelessWidget {
  const _ResumenTab({required this.student});
  final AppUser student;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Información personal', style: AppTextStyles.h3),
              const SizedBox(height: 14),
              _InfoRow(icon: Icons.tag_rounded, label: 'Código', value: student.code ?? '—'),
              const Divider(height: 24, color: AppColors.divider),
              _InfoRow(icon: Icons.badge_outlined, label: 'Documento', value: student.document ?? '—'),
              const Divider(height: 24, color: AppColors.divider),
              _InfoRow(icon: Icons.mail_outline_rounded, label: 'Correo', value: student.email),
              const Divider(height: 24, color: AppColors.divider),
              _InfoRow(icon: Icons.phone_outlined, label: 'Teléfono', value: student.phone ?? '—'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Acudientes', style: AppTextStyles.h3),
              const SizedBox(height: 14),
              for (final g in student.guardians)
                Row(
                  children: [
                    AvatarCircle(name: g.name, radius: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                          Text('${g.relation} · ${g.phone}', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              if (student.guardians.isEmpty) Text('Sin acudientes registrados.', style: AppTextStyles.bodyMuted),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, _) {
            final gradesAsync = ref.watch(gradesForStudentProvider(student.id));
            return SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: 'Notas recientes', trailingText: 'Ver todo'),
                  const SizedBox(height: 12),
                  gradesAsync.when(
                    data: (grades) => Column(
                      children: [
                        for (final g in grades.take(3))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(g.subject, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                                Row(
                                  children: [
                                    Text(g.qualitative, style: AppTextStyles.caption),
                                    const SizedBox(width: 8),
                                    Text(g.score.toStringAsFixed(1),
                                        style: AppTextStyles.body
                                            .copyWith(color: g.color, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTextStyles.caption)),
        Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _NotasTab extends ConsumerWidget {
  const _NotasTab({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesAsync = ref.watch(gradesForStudentProvider(studentId));
    return gradesAsync.when(
      data: (grades) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          SectionCard(
            child: Column(
              children: [
                for (int i = 0; i < grades.length; i++) ...[
                  _GradeBar(grade: grades[i]),
                  if (i != grades.length - 1) const SizedBox(height: 16),
                ],
                if (grades.isEmpty) Text('Sin notas registradas.', style: AppTextStyles.bodyMuted),
              ],
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('No se pudieron cargar las notas.')),
    );
  }
}

class _GradeBar extends StatelessWidget {
  const _GradeBar({required this.grade});
  final Grade grade;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(grade.subject, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
            Text(grade.score.toStringAsFixed(1),
                style: AppTextStyles.body.copyWith(color: grade.color, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (grade.score / 10).clamp(0, 1),
            minHeight: 8,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation(grade.color),
          ),
        ),
      ],
    );
  }
}

class _AsistenciaTab extends ConsumerWidget {
  const _AsistenciaTab({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceForStudentProvider(studentId));
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
                  Text('Asistencia general', style: AppTextStyles.bodyMuted),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                          child: _AttendanceStat(
                              label: 'Presentes', value: '${attendance.present}', color: AppColors.tealDark)),
                      Expanded(
                          child: _AttendanceStat(
                              label: 'Ausentes', value: '${attendance.absent}', color: AppColors.pink)),
                      Expanded(
                          child: _AttendanceStat(
                              label: 'Tardanzas', value: '${attendance.late}', color: AppColors.orange)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('No se pudo cargar la asistencia.')),
    );
  }
}

class _AttendanceStat extends StatelessWidget {
  const _AttendanceStat({required this.label, required this.value, required this.color});
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

class _NovedadesTab extends ConsumerWidget {
  const _NovedadesTab({required this.studentId});
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novedadesAsync = ref.watch(novedadesForStudentProvider(studentId));
    return novedadesAsync.when(
      data: (novedades) {
        if (novedades.isEmpty) {
          return Center(child: Text('Sin novedades registradas.', style: AppTextStyles.bodyMuted));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          itemCount: novedades.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final n = novedades[index];
            final dotColor = switch (n.severity) {
              NovedadSeverity.high => AppColors.pink,
              NovedadSeverity.medium => AppColors.orange,
              NovedadSeverity.low => AppColors.blue,
            };
            return SectionCard(
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(n.title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600))),
                  Text(n.timeAgo, style: AppTextStyles.caption),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('No se pudieron cargar las novedades.')),
    );
  }
}
