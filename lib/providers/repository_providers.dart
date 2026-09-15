import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eyes_school/core/network/dio_client.dart';
import 'package:eyes_school/core/storage/local_store.dart';
import 'package:eyes_school/core/storage/token_storage.dart';
import 'package:eyes_school/core/sync/sync_worker.dart';
import 'package:eyes_school/features/academic/data/academic_api.dart';
import 'package:eyes_school/core/network/api_client.dart';
import 'package:eyes_school/features/attendance/data/attendance_api.dart';
import 'package:eyes_school/features/auth/data/auth_api.dart';
import 'package:eyes_school/features/dashboard/data/dashboard_api.dart';
import 'package:eyes_school/features/novedades/data/novedades_api.dart';
import 'package:eyes_school/features/directory/data/people_api.dart';
import 'package:eyes_school/features/reports/data/reportes_api.dart';
import 'package:eyes_school/features/attendance/data/attendance_queue.dart';
import 'package:eyes_school/features/directory/data/student_catalog.dart';
import 'package:eyes_school/features/academic/data/academic_repository_impl.dart';
import 'package:eyes_school/features/attendance/data/attendance_repository_impl.dart';
import 'package:eyes_school/features/auth/data/auth_repository_impl.dart';
import 'package:eyes_school/features/directory/data/catalog_repository_impl.dart';
import 'package:eyes_school/features/directory/data/directory_repository_impl.dart';
import 'package:eyes_school/features/reports/data/report_repository_impl.dart';
import 'package:eyes_school/core/domain/repositories.dart';
import 'package:eyes_school/core/domain/usecases.dart';

/// Composition root.
///
/// Everything above this file depends on the **domain contracts**; the only
/// place that knows which implementation backs them is here. That is what
/// makes a repository swappable — for a fake in a test, or for a different
/// backend later — without touching a single screen.

/// Lets the Dio auth interceptor tell the session that the refresh token was
/// rejected, without the network layer depending on Riverpod.
class SessionExpirySignal {
  Future<void> Function()? onExpired;

  Future<void> fire() async => onExpired?.call();
}

final sessionExpiryProvider = Provider<SessionExpirySignal>((ref) => SessionExpirySignal());

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final localStoreProvider = Provider<LocalStore>((ref) => LocalStore());

final dioProvider = Provider<Dio>((ref) {
  return buildDio(
    tokens: ref.watch(tokenStorageProvider),
    onSessionExpired: ref.watch(sessionExpiryProvider).fire,
  );
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(dioProvider)));

// ── Data sources ──────────────────────────────────────────────────────────

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));

final peopleApiProvider =
    Provider<PeopleApi>((ref) => PeopleApi(ref.watch(apiClientProvider)));

final academicApiProvider =
    Provider<AcademicApi>((ref) => AcademicApi(ref.watch(apiClientProvider)));

final attendanceApiProvider =
    Provider<AttendanceApi>((ref) => AttendanceApi(ref.watch(apiClientProvider)));

final novedadesApiProvider =
    Provider<NovedadesApi>((ref) => NovedadesApi(ref.watch(apiClientProvider)));

final dashboardApiProvider =
    Provider<DashboardApi>((ref) => DashboardApi(ref.watch(apiClientProvider)));

final reportesApiProvider =
    Provider<ReportesApi>((ref) => ReportesApi(ref.watch(apiClientProvider)));

/// Catalog that resolves a scanned `codigo_estudiante` to an id, and the
/// reason offline scanning works at all.
final studentCatalogProvider = Provider<StudentCatalog>((ref) {
  return StudentCatalog(
    api: ref.watch(peopleApiProvider),
    store: ref.watch(localStoreProvider),
  );
});

/// Write-behind queue for attendance. A [ChangeNotifier], so widgets can
/// listen to it for the pending badge.
final attendanceQueueProvider = ChangeNotifierProvider<AttendanceQueue>((ref) {
  return AttendanceQueue(
    api: ref.watch(attendanceApiProvider),
    store: ref.watch(localStoreProvider),
  );
});

/// Started once a session opens: retries on reconnect, on resume and on a
/// slow tick.
final syncWorkerProvider = Provider<SyncWorker>((ref) {
  final worker = SyncWorker(ref.watch(attendanceQueueProvider));
  ref.onDispose(worker.dispose);
  return worker;
});

final connectivityProvider = StreamProvider<bool>((ref) => connectivityStream());

// ── Repositories (contract → implementation) ──────────────────────────────

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepositoryImpl(
    academic: ref.watch(academicApiProvider),
    novedades: ref.watch(novedadesApiProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    auth: ref.watch(authApiProvider),
    people: ref.watch(peopleApiProvider),
    dashboard: ref.watch(dashboardApiProvider),
    catalogs: ref.watch(catalogRepositoryProvider),
    tokens: ref.watch(tokenStorageProvider),
  );
});

final directoryRepositoryProvider = Provider<DirectoryRepository>((ref) {
  return DirectoryRepositoryImpl(
    people: ref.watch(peopleApiProvider),
    academic: ref.watch(academicApiProvider),
    catalogs: ref.watch(catalogRepositoryProvider),
    students: ref.watch(studentCatalogProvider),
  );
});

final academicRepositoryProvider = Provider<AcademicRepository>((ref) {
  return AcademicRepositoryImpl(
    academic: ref.watch(academicApiProvider),
    novedades: ref.watch(novedadesApiProvider),
    people: ref.watch(peopleApiProvider),
    dashboard: ref.watch(dashboardApiProvider),
    catalogs: ref.watch(catalogRepositoryProvider),
  );
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepositoryImpl(
    api: ref.watch(attendanceApiProvider),
    catalog: ref.watch(studentCatalogProvider),
    queue: ref.watch(attendanceQueueProvider),
  );
});

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepositoryImpl(ref.watch(reportesApiProvider)),
);

// ── Use cases ─────────────────────────────────────────────────────────────

final signInProvider = Provider((ref) => SignIn(ref.watch(authRepositoryProvider)));

final restoreSessionProvider =
    Provider((ref) => RestoreSession(ref.watch(authRepositoryProvider)));

final registerScanProvider =
    Provider((ref) => RegisterScan(ref.watch(attendanceRepositoryProvider)));

final registerCourseAttendanceProvider =
    Provider((ref) => RegisterCourseAttendance(ref.watch(attendanceRepositoryProvider)));

final saveGradeSheetProvider =
    Provider((ref) => SaveGradeSheet(ref.watch(academicRepositoryProvider)));

final nameNovedadesProvider =
    Provider((ref) => NameNovedades(ref.watch(attendanceRepositoryProvider)));

const todaysClasses = TodaysClasses();
const nextClass = NextClass();
