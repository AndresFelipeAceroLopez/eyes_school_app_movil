import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../core/widgets/weekly_schedule_list.dart';
import '../../models/class_session.dart';
import '../../providers/data_providers.dart';
import 'class_roster_screen.dart';

class TeacherClassesScreen extends ConsumerWidget {
  const TeacherClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(teacherWeeklyScheduleProvider);

    return SimpleHeaderScaffold(
      title: 'Mis clases',
      showBack: false,
      body: scheduleAsync.when(
        data: (sessions) => ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            WeeklyScheduleList(
              sessions: sessions,
              onTapSession: (session) => _openRoster(context, session),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text('No se pudo cargar el horario.', style: AppTextStyles.bodyMuted)),
      ),
    );
  }

  void _openRoster(BuildContext context, ClassSession session) {
    final group = session.group.split(' · ').first;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ClassRosterScreen(group: group, subject: session.subject),
    ));
  }
}
