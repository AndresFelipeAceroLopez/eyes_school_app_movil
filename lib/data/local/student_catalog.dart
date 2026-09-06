import '../../core/constants/app_constants.dart';
import '../../core/network/api_config.dart';
import '../../core/storage/local_store.dart';
import '../../domain/entities/attendance_record.dart';
import '../api/people_api.dart';
import '../dto/people_dto.dart';

/// Local catalog of students, keyed by `codigo_estudiante`.
///
/// The API has no "find student by code" endpoint, and a QR encodes nothing
/// but that code, so a scan has to be resolved locally. The cache is also what
/// makes offline scanning possible at all, so it stays even if the endpoint
/// ships one day.
class StudentCatalog {
  StudentCatalog({required this._api, required this._store});

  static const _dataKey = 'students_cache';
  static const _metaKey = 'students_cache_meta';

  /// A forced refresh pages the whole student list, so an unknown code cannot
  /// be allowed to trigger one on every scan.
  static const _forcedRefreshCooldown = Duration(minutes: 2);

  final PeopleApi _api;
  final LocalStore _store;

  final Map<String, StudentIdentity> _byCode = {};
  final Map<int, StudentIdentity> _byId = {};
  DateTime? _refreshedAt;
  DateTime? _lastForcedAt;
  bool _loaded = false;
  Future<void>? _inFlight;

  int get size => _byId.length;
  DateTime? get refreshedAt => _refreshedAt;

  bool get isStale {
    final at = _refreshedAt;
    return at == null || DateTime.now().difference(at) > AppConstants.studentCacheTtl;
  }

  /// Loads from disk (fast) and refreshes from the API when missing or stale.
  Future<void> ensureReady({bool force = false}) {
    return _inFlight ??= _ensureReady(force: force).whenComplete(() => _inFlight = null);
  }

  Future<void> _ensureReady({required bool force}) async {
    if (!_loaded) await _loadFromDisk();

    // The cooldown never applies while there is nothing to fall back on.
    if (force && !_forcedRefreshAllowed && _byId.isNotEmpty) return;
    if (!force && _byId.isNotEmpty && !isStale) return;

    if (force) _lastForcedAt = DateTime.now();
    try {
      await _refreshFromApi();
    } catch (_) {
      // Offline: whatever is on disk is still perfectly usable for scanning.
      if (_byId.isEmpty) rethrow;
    }
  }

  bool get _forcedRefreshAllowed {
    final last = _lastForcedAt;
    return last == null || DateTime.now().difference(last) > _forcedRefreshCooldown;
  }

  Future<void> _loadFromDisk() async {
    _loaded = true;
    final rows = await _store.readList(_dataKey);
    for (final row in rows) {
      _index(StudentIdentityMapper.fromJson(row.cast<String, dynamic>()));
    }
    final meta = await _store.read<Map<String, dynamic>>(_metaKey);
    final at = meta?['refreshed_at'];
    if (at is String) _refreshedAt = DateTime.tryParse(at);
  }

  Future<void> _refreshFromApi() async {
    final all = <StudentIdentity>[];
    for (var skip = 0;; skip += ApiConfig.catalogPageSize) {
      final page = await _api.students(skip: skip, limit: ApiConfig.catalogPageSize);
      all.addAll(page.map((e) => e.toIdentity()));
      if (page.length < ApiConfig.catalogPageSize) break;
      // Hard stop so a misbehaving endpoint cannot page forever.
      if (skip > 20000) break;
    }
    if (all.isEmpty && _byId.isNotEmpty) return;

    _byCode.clear();
    _byId.clear();
    for (final student in all) {
      _index(student);
    }
    _refreshedAt = DateTime.now();

    await _store.write(_dataKey, all.map(StudentIdentityMapper.toJson).toList());
    await _store.write(_metaKey, {'refreshed_at': _refreshedAt!.toIso8601String()});
  }

  void _index(StudentIdentity student) {
    _byId[student.studentId] = student;
    final code = student.code.trim();
    if (code.isNotEmpty) _byCode[code.toUpperCase()] = student;
  }

  /// O(1) lookup of a scanned code.
  StudentIdentity? byCode(String code) => _byCode[code.trim().toUpperCase()];

  StudentIdentity? byId(int studentId) => _byId[studentId];

  List<StudentIdentity> get all => _byId.values.toList();

  /// Local search over name, code and course — used by the admin directory and
  /// by manual attendance when there is no signal.
  List<StudentIdentity> search(String query, {int? courseId, int limit = 30}) {
    final needle = query.trim().toLowerCase();
    final result = <StudentIdentity>[];
    for (final student in _byId.values) {
      if (courseId != null && student.courseId != courseId) continue;
      if (needle.isNotEmpty) {
        final haystack = '${student.fullName} ${student.code}'.toLowerCase();
        if (!haystack.contains(needle)) continue;
      }
      result.add(student);
      if (result.length >= limit) break;
    }
    result.sort((a, b) => a.displayName.compareTo(b.displayName));
    return result;
  }

  Future<void> clear() async {
    _byCode.clear();
    _byId.clear();
    _refreshedAt = null;
    _lastForcedAt = null;
    _loaded = false;
    await _store.delete(_dataKey);
    await _store.delete(_metaKey);
  }
}
