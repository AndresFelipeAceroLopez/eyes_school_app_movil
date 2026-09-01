import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Initials-based avatar (no network images needed for the mock data).
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.name,
    this.radius = 26,
    this.background,
    this.foreground = Colors.white,
  });

  final String name;
  final double radius;
  final Color? background;
  final Color foreground;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Color _colorFromName() {
    const palette = [
      AppColors.indigo,
      AppColors.tealDark,
      AppColors.blue,
      AppColors.roleParent,
      AppColors.violet,
    ];
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    return palette[hash % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: background ?? _colorFromName(),
      child: Text(
        _initials,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
