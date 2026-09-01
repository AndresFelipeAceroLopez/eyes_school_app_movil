import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/section_header.dart';
import '../../models/user.dart';
import '../../providers/data_providers.dart';
import '../../providers/session_provider.dart';

class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).value;
    if (user == null) return const SizedBox.shrink();

    final childrenAsync = ref.watch(childrenOfProvider(user));
    final activityAsync = ref.watch(parentRecentActivityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(childrenOfProvider(user));
          ref.invalidate(parentRecentActivityProvider);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.headerGradient,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AvatarCircle(name: user.name, radius: 26),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Padre / Acudiente', style: AppTextStyles.statLabel),
                            Text(
                              'Hola, ${user.firstName}',
                              style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 22),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration:
                            BoxDecoration(color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle),
                        child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(width: 3, height: 16, color: AppColors.teal),
                      const SizedBox(width: 8),
                      Text('EYESCHOOL',
                          style: AppTextStyles.statLabel.copyWith(letterSpacing: 2, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: childrenAsync.when(
                data: (children) => SectionHeader(title: 'Mis hijos', trailingText: '${children.length} vinculados'),
                loading: () => const SectionHeader(title: 'Mis hijos'),
                error: (_, _) => const SectionHeader(title: 'Mis hijos'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: childrenAsync.when(
                data: (children) => Column(
                  children: children
                      .map((child) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _ChildCard(
                              child: child,
                              onTap: () => context.push('/students/${child.id}'),
                            ),
                          ))
                      .toList(),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Text('No se pudieron cargar tus hijos.', style: AppTextStyles.bodyMuted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: SectionHeader(title: 'Novedades recientes', trailingText: 'Ver todo'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: activityAsync.when(
                data: (activity) => SectionCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < activity.length; i++)
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: activity[i].iconBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(activity[i].icon, size: 20, color: activity[i].iconColor),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(activity[i].title,
                                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                                  ),
                                  Text(activity[i].timeAgo, style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                            if (i != activity.length - 1)
                              const Divider(height: 1, color: AppColors.divider, indent: 16, endIndent: 16),
                          ],
                        ),
                    ],
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Text('No se pudieron cargar las novedades.', style: AppTextStyles.bodyMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child, required this.onTap});

  final AppUser child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarCircle(name: child.name, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.name, style: AppTextStyles.h3),
                      Text(child.grade ?? '', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricChip(label: 'Promedio', value: '${child.average}', color: AppColors.tealDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricChip(
                    label: 'Asistencia',
                    value: '${child.attendancePercent?.round()}%',
                    color: AppColors.indigo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.h3.copyWith(color: color)),
        ],
      ),
    );
  }
}
