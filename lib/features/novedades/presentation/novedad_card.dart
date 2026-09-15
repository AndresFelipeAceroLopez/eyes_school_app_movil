import 'package:flutter/material.dart';

import 'package:eyes_school/features/novedades/domain/novedad.dart';
import 'package:eyes_school/core/theme/app_colors.dart';
import 'package:eyes_school/core/theme/domain_styles.dart';
import 'package:eyes_school/core/utils/formatters.dart';
import 'package:eyes_school/core/theme/app_text_styles.dart';
import 'package:eyes_school/features/directory/presentation/avatar_circle.dart';
import 'package:eyes_school/core/widgets/section_header.dart';

/// One news item. Shared by the teacher tray, the admin tray and the student
/// and guardian lists, so a severity always reads the same everywhere.
class NovedadCard extends StatelessWidget {
  const NovedadCard({
    super.key,
    required this.novedad,
    this.showStudent = true,
    this.onTap,
    this.trailing,
  });

  final Novedad novedad;

  /// Off on the student's own list, where every row is about them.
  final bool showStudent;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final content = SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showStudent) ...[
                AvatarCircle(name: novedad.studentName, radius: 22),
                const SizedBox(width: 12),
              ] else ...[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: novedad.severity.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.campaign_rounded, color: novedad.severity.color),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showStudent ? novedad.studentName : novedad.title,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      showStudent ? novedad.title : Formatters.timeAgo(novedad.date),
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: novedad.severity.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        novedad.severity.label,
                        style: AppTextStyles.caption.copyWith(
                          color: novedad.severity.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      showStudent ? Formatters.timeAgo(novedad.date) : '',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
            ],
          ),
          if (novedad.description != null && novedad.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              novedad.description!,
              style: AppTextStyles.caption,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (novedad.resolved) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.tealDark),
                const SizedBox(width: 6),
                Text(
                  'Completada',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.tealDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: content,
    );
  }
}
