import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../models/novedad.dart';
import '../../providers/data_providers.dart';

class TeacherNovedadesScreen extends ConsumerWidget {
  const TeacherNovedadesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novedadesAsync = ref.watch(teacherPendingNovedadesProvider);

    return SimpleHeaderScaffold(
      title: 'Novedades pendientes',
      body: novedadesAsync.when(
        data: (novedades) {
          if (novedades.isEmpty) {
            return Center(child: Text('No hay novedades pendientes.', style: AppTextStyles.bodyMuted));
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
                    AvatarCircle(name: n.studentName, radius: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.studentName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                          Text(n.title, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(height: 6),
                        Text(n.timeAgo, style: AppTextStyles.caption),
                      ],
                    ),
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
