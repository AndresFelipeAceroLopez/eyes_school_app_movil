import 'package:flutter/material.dart';

import '../../domain/entities/role.dart';
import '../../domain/entities/app_user.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.active, this.activeLabel = 'Activo', this.inactiveLabel = 'Inactivo'});

  final bool active;
  final String activeLabel;
  final String inactiveLabel;

  @override
  Widget build(BuildContext context) {
    final bg = active ? AppColors.statusActiveBg : AppColors.statusInactiveBg;
    final fg = active ? AppColors.statusActiveFg : AppColors.statusInactiveFg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          Text(
            active ? activeLabel : inactiveLabel,
            style: AppTextStyles.caption.copyWith(color: fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final Role role;

  (Color, Color) get _colors => switch (role) {
        Role.teacher => (AppColors.roleTeacherBg, AppColors.roleTeacher),
        Role.student => (AppColors.roleStudentBg, AppColors.roleStudent),
        Role.admin => (AppColors.roleAdminBg, AppColors.roleAdmin),
        Role.parent => (AppColors.roleParentBg, AppColors.roleParent),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        role.label,
        style: AppTextStyles.caption.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

extension AccountStatusX on AccountStatus {
  bool get isActive => this == AccountStatus.active;
}
