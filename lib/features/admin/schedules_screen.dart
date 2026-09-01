import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/simple_header_scaffold.dart';
import '../../core/widgets/weekly_schedule_list.dart';
import '../../providers/data_providers.dart';

class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key});

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen> {
  String _group = '8°A';
  static const _groups = ['8°A', '9°B', '10°C'];

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(teacherWeeklyScheduleProvider);

    return SimpleHeaderScaffold(
      title: 'Horarios',
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: _groups
                  .map((g) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Text('Grado $g'),
                          selected: _group == g,
                          onSelected: (_) => setState(() => _group = g),
                          selectedColor: AppColors.indigo,
                          labelStyle: AppTextStyles.body.copyWith(
                            color: _group == g ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: BorderSide.none,
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: scheduleAsync.when(
              data: (sessions) {
                final filtered = sessions.where((s) => s.group.startsWith(_group)).toList();
                return ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [WeeklyScheduleList(sessions: filtered)],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text('No se pudo cargar el horario.', style: AppTextStyles.bodyMuted)),
            ),
          ),
        ],
      ),
    );
  }
}
