import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../core/widgets/weekly_schedule_list.dart';
import '../../providers/data_providers.dart';
import '../../providers/session_provider.dart';

class StudentScheduleScreen extends ConsumerWidget {
  const StudentScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).value;
    if (user == null) return const SizedBox.shrink();
    final scheduleAsync = ref.watch(studentWeeklyScheduleProvider(user.id));

    return SimpleHeaderScaffold(
      title: 'Mi horario',
      showBack: false,
      body: scheduleAsync.when(
        data: (sessions) => ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [WeeklyScheduleList(sessions: sessions)],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text('No se pudo cargar el horario.', style: AppTextStyles.bodyMuted)),
      ),
    );
  }
}
