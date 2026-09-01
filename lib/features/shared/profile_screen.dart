import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_badge.dart';
import '../../providers/session_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider);
    final user = sessionAsync.value;

    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Text('Perfil', style: AppTextStyles.h1),
            const SizedBox(height: 20),
            SectionCard(
              child: Column(
                children: [
                  AvatarCircle(name: user.name, radius: 36),
                  const SizedBox(height: 14),
                  Text(user.name, style: AppTextStyles.h2),
                  const SizedBox(height: 6),
                  RoleBadge(role: user.role),
                  if (user.subject != null) ...[
                    const SizedBox(height: 6),
                    Text(user.subject!, style: AppTextStyles.bodyMuted),
                  ],
                  if (user.grade != null) ...[
                    const SizedBox(height: 6),
                    Text('${user.grade} · ${user.jornada ?? ''}', style: AppTextStyles.bodyMuted),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Información de la cuenta', style: AppTextStyles.h3),
                  const SizedBox(height: 14),
                  _InfoRow(icon: Icons.mail_outline_rounded, label: 'Correo', value: user.email),
                  if (user.phone != null) ...[
                    const Divider(height: 24, color: AppColors.divider),
                    _InfoRow(icon: Icons.phone_outlined, label: 'Teléfono', value: user.phone!),
                  ],
                  if (user.institution != null) ...[
                    const Divider(height: 24, color: AppColors.divider),
                    _InfoRow(
                        icon: Icons.school_outlined, label: 'Institución', value: user.institution!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.pink,
                  side: const BorderSide(color: AppColors.pink),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => ref.read(sessionProvider.notifier).logout(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
              ),
            ),
          ],
        ),
      ),
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
