import 'package:eyes_school/features/academic/domain/class_time.dart';

/// Operational settings of the mobile client.
///
/// Academic facts (the four periods, the school week, the 0.0–5.0 scale) are
/// domain knowledge and live in `domain/value_objects`; what stays here is how
/// *this app* behaves: how long a cache is good for, how fast it debounces,
/// how many requests it fires at once.
abstract final class AppConstants {
  /// A scan after this hour is suggested as `Tarde` instead of `Presente`.
  static const ClassTime entryCutoff = ClassTime(7, 15);

  /// The student catalog that resolves scanned QR codes is refreshed when it
  /// is older than this, or on pull-to-refresh.
  static const Duration studentCacheTtl = Duration(hours: 12);

  /// Same code scanned twice inside this window counts once.
  static const Duration scanDebounce = Duration(milliseconds: 1500);

  /// Concurrency for bulk attendance: the API has no batch endpoint, so a
  /// 35-student course is 35 POSTs.
  static const int bulkConcurrency = 5;
}
