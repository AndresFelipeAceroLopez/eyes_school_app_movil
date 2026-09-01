import 'package:flutter/material.dart';

class ActivityLog {
  const ActivityLog({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String timeAgo;
}
