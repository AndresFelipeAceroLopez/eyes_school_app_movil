import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../models/novedad.dart';
import '../../providers/data_providers.dart';
import '../../providers/session_provider.dart';

class StudentNovedadesScreen extends ConsumerWidget {
  const StudentNovedadesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).value;
    if (user == null) return const SizedBox.shrink();
    final novedadesAsync = ref.watch(novedadesForStudentProvider(user.id));

    return SimpleHeaderScaffold(
      title: 'Mis novedades',
      showBack: false,
      body: novedadesAsync.when(
        data: (novedades) {
          if (novedades.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.tealDark),
                  const SizedBox(height: 12),
                  Text('No tienes novedades registradas.', style: AppTextStyles.bodyMuted),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            itemCount: novedades.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final n = novedades[index];
              final color = switch (n.severity) {
                NovedadSeverity.high => AppColors.pink,
                NovedadSeverity.medium => AppColors.orange,
                NovedadSeverity.low => AppColors.blue,
              };
              return SectionCard(
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
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
        error: (_, _) => Center(child: Text('No se pudieron cargar las novedades.', style: AppTextStyles.bodyMuted)),
      ),
    );
  }
}
