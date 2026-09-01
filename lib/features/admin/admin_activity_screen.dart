import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../providers/data_providers.dart';

class AdminActivityScreen extends ConsumerWidget {
  const AdminActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(adminRecentActivityProvider);

    return SimpleHeaderScaffold(
      title: 'Actividad reciente',
      body: activityAsync.when(
        data: (activity) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          itemCount: activity.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final a = activity[index];
            return SectionCard(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: a.iconBg, borderRadius: BorderRadius.circular(12)),
                    child: Icon(a.icon, size: 20, color: a.iconColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                        Text(a.subtitle, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Text(a.timeAgo, style: AppTextStyles.caption),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text('No se pudo cargar la actividad.', style: AppTextStyles.bodyMuted)),
      ),
    );
  }
}
