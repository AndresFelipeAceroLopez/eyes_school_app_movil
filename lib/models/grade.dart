import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class Grade {
  const Grade({
    required this.subject,
    required this.score,
    required this.period,
  });

  final String subject;
  final double score;
  final String period;

  String get qualitative {
    if (score >= 9.0) return 'Excelente';
    if (score >= 7.0) return 'Bueno';
    if (score >= 6.0) return 'Aceptable';
    return 'Bajo';
  }

  Color get color => score >= 9.0 ? AppColors.teal : AppColors.indigo;
}
