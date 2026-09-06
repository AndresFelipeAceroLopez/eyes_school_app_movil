import 'package:flutter/material.dart';

abstract final class Formatters {
  static const _weekdays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static const _months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  /// e.g. "Lunes 19 Ago"
  static String todayLong(DateTime date) {
    final weekday = _weekdays[date.weekday - 1];
    final month = _months[date.month - 1];
    return '$weekday ${date.day} $month';
  }

  /// e.g. "19 Ago 2026"
  static String dateShort(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  /// e.g. "19/08/2026"
  static String dateNumeric(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  /// `TimeOfDay` → `"07:00"`. The API sends `"07:00:00"`, which is not ISO.
  static String time(TimeOfDay? time) {
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  /// Relative label for activity feeds and news lists.
  static String timeAgo(DateTime? moment) {
    if (moment == null) return '';
    final diff = DateTime.now().difference(moment);
    if (diff.isNegative) return 'Programado';
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    if (diff.inDays < 30) return 'Hace ${(diff.inDays / 7).floor()} sem';
    if (diff.inDays < 365) return 'Hace ${(diff.inDays / 30).floor()} meses';
    return dateShort(moment);
  }

  /// 3.87 → "3.9"; null → "—".
  static String grade(double? value) => value == null ? '—' : value.toStringAsFixed(1);

  /// 0.9412 or 94.12 → "94%". The API is inconsistent about whether a
  /// percentage arrives as a fraction or as a number out of a hundred.
  static String percent(double? value) {
    if (value == null) return '—';
    final normalized = value <= 1 && value > 0 ? value * 100 : value;
    return '${normalized.round()}%';
  }

  static double normalizePercent(double? value) {
    if (value == null) return 0;
    return (value <= 1 && value > 0 ? value * 100 : value).clamp(0, 100).toDouble();
  }
}
