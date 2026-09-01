import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../models/novedad.dart';
import '../../providers/data_providers.dart';

class AdminNovedadesScreen extends ConsumerWidget {
  const AdminNovedadesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novedadesAsync = ref.watch(adminNovedadesProvider);

    return SimpleHeaderScaffold(
      title: 'Novedades',
      body: novedadesAsync.when(
        data: (novedades) {
          if (novedades.isEmpty) {
            return Center(child: Text('No hay novedades registradas.', style: AppTextStyles.bodyMuted));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            itemCount: novedades.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final n = novedades[index];
              final (bg, fg, label) = switch (n.severity) {
                NovedadSeverity.high => (const Color(0xFFFFE7EC), AppColors.pink, 'Alta'),
                NovedadSeverity.medium => (const Color(0xFFFCEEDD), AppColors.orange, 'Media'),
                NovedadSeverity.low => (AppColors.roleStudentBg, AppColors.blue, 'Baja'),
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
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              label,
                              style: AppTextStyles.caption.copyWith(color: fg, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
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
