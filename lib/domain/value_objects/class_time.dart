/// A time of day on the school clock, independent of Flutter.
///
/// The API sends `"07:00:00"` (`format: time`), which is not an ISO datetime,
/// so it cannot go through `DateTime.parse`. Keeping the domain free of
/// `TimeOfDay` is what lets schedules be reasoned about — and unit tested —
/// without the widget layer.
class ClassTime implements Comparable<ClassTime> {
  const ClassTime(this.hour, this.minute);

  /// Parses `"07:00"` or `"07:00:00"`. Returns `null` for anything else
  /// rather than throwing: one unreadable block must not blank a whole grid.
  static ClassTime? tryParse(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    final parts = text.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return ClassTime(hour % 24, minute % 60);
  }

  static ClassTime fromDateTime(DateTime moment) =>
      ClassTime(moment.hour, moment.minute);

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  /// `"07:00"`.
  String get formatted =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  ClassTime plusMinutes(int minutes) {
    final total = (minutesOfDay + minutes) % (24 * 60);
    return ClassTime(total ~/ 60, total % 60);
  }

  @override
  int compareTo(ClassTime other) => minutesOfDay.compareTo(other.minutesOfDay);

  bool operator <(ClassTime other) => minutesOfDay < other.minutesOfDay;
  bool operator >(ClassTime other) => minutesOfDay > other.minutesOfDay;

  @override
  bool operator ==(Object other) =>
      other is ClassTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => formatted;
}
