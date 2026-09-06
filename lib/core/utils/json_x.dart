import 'package:flutter/material.dart';

/// Defensive readers for the API payloads. FastAPI is consistent, but a few
/// fields are declared loosely (`nota` is `number`, so it can arrive as int or
/// double) and several are nullable in practice even when the schema says
/// otherwise. Parsing must never throw and take a whole screen down.
typedef Json = Map<String, dynamic>;

int asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? asIntOrNull(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double asDouble(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

double? asDoubleOrNull(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool asBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return fallback;
}

String asString(Object? value, {String fallback = ''}) =>
    value == null ? fallback : value.toString();

String? asStringOrNull(Object? value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty) ? null : text;
}

/// `format: date` → `"2026-09-06"`, `format: date-time` → ISO 8601.
DateTime? asDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

/// The API sends `hora_inicio` / `hora_fin` as `"07:00:00"` (`format: time`),
/// which is not ISO datetime and cannot go through `DateTime.parse`.
TimeOfDay? asTime(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  final parts = text.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour % 24, minute: minute % 60);
}

/// `[{...}, {...}]` → typed list, skipping anything that is not an object.
List<T> asList<T>(Object? value, T Function(Json json) mapper) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((e) => mapper(e.cast<String, dynamic>())).toList();
}

/// `yyyy-MM-dd`, the only date format the API accepts on writes.
String toApiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
