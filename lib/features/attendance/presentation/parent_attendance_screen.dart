import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/core/widgets/async_states.dart';
import 'package:eyes_school/features/directory/presentation/avatar_circle.dart';
import 'package:eyes_school/core/widgets/section_header.dart';
import 'package:eyes_school/core/widgets/simple_header_scaffold.dart';
import 'package:eyes_school/providers/session_provider.dart';
import 'package:eyes_school/features/attendance/presentation/attendance_history_view.dart';

/// The linked child's attendance history, with the same paginated view the
/// student sees about themselves.
class ParentAttendanceScreen extends ConsumerWidget {
  const ParentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);
    final childId = session?.childId;

    if (childId == null) {
      return SimpleHeaderScaffold(
        title: 'Asistencia',
        showBack: false,
        body: EmptyState(
          icon: Icons.family_restroom_rounded,
          title: 'Sin estudiante vinculado',
          message: session?.bootstrapWarning ??
              'Tu cuenta de acudiente aún no está vinculada a un estudiante.',
        ),
      );
    }

    final name = session?.childName ?? 'Estudiante';

    return SimpleHeaderScaffold(
      title: 'Asistencia',
      showBack: false,
      body: AttendanceHistoryView(
        studentId: childId,
        header: SectionCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              AvatarCircle(name: name, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (session?.childDocument != null)
                      Text(session!.childDocument!, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
