import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/async_states.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../core/widgets/status_badge.dart';
import '../../domain/entities/app_user.dart';
import '../../providers/data_providers.dart';

/// Teacher card in the admin directory: identity, specializations and the
/// courses they are assigned to.
class TeacherProfileScreen extends ConsumerWidget {
  const TeacherProfileScreen({super.key, required this.teacherId});

  final int teacherId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherAsync = ref.watch(teacherProfileProvider(teacherId));

    return SimpleHeaderScaffold(
      title: 'Docente',
      body: teacherAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(teacherProfileProvider(teacherId)),
        ),
        data: (teacher) {
          if (teacher == null) {
            return const EmptyState(
              icon: Icons.person_search_rounded,
              title: 'Docente no encontrado',
              message: 'Este perfil ya no está disponible.',
            );
          }
          return _body(context, ref, teacher);
        },
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, AppUser teacher) {
    final coursesAsync = ref.watch(teacherCoursesProvider(teacherId));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        SectionCard(
          child: Column(
            children: [
              AvatarCircle(name: teacher.name, radius: 36),
              const SizedBox(height: 14),
              Text(teacher.name, style: AppTextStyles.h2, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              RoleBadge(role: teacher.role),
              const SizedBox(height: 8),
              StatusBadge(active: teacher.isActive),
              if (teacher.code != null) ...[
                const SizedBox(height: 8),
                Text(teacher.code!, style: AppTextStyles.bodyMuted),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Información', style: AppTextStyles.h3),
              const SizedBox(height: 14),
              if (teacher.subject != null)
                _InfoRow(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Especialización',
                  value: teacher.subject!,
                ),
              if (teacher.institution != null) ...[
                const Divider(height: 24, color: AppColors.divider),
                _InfoRow(
                  icon: Icons.school_outlined,
                  label: 'Nivel de estudios',
                  value: teacher.institution!,
                ),
              ],
              if (teacher.email.isNotEmpty) ...[
                const Divider(height: 24, color: AppColors.divider),
                _InfoRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'Correo',
                  value: teacher.email,
                ),
              ],
              if (teacher.phone != null) ...[
                const Divider(height: 24, color: AppColors.divider),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: teacher.phone!,
                ),
              ],
              if (teacher.document != null) ...[
                const Divider(height: 24, color: AppColors.divider),
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Documento',
                  value: teacher.document!,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cursos asignados', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              coursesAsync.when(
                loading: () => const LoadingView(padding: EdgeInsets.symmetric(vertical: 16)),
                error: (_, _) => Text('No pudimos cargar las asignaciones.',
                    style: AppTextStyles.bodyMuted),
                data: (courses) => courses.isEmpty
                    ? Text('Sin asignaciones activas.', style: AppTextStyles.bodyMuted)
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: courses
                            .map((c) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: AppColors.roleTeacherBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    c,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.roleTeacher,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
              ),
            ],
          ),
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
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
