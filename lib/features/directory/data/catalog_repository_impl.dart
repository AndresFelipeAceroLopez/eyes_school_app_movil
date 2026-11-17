import 'package:eyes_school/features/directory/domain/catalog.dart';
import 'package:eyes_school/features/novedades/domain/novedad.dart';
import 'package:eyes_school/core/domain/repositories.dart';
import 'package:eyes_school/features/academic/data/academic_api.dart';
import 'package:eyes_school/features/novedades/data/novedades_api.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl({required this._academic, required this._novedades});

  final AcademicApi _academic;
  final NovedadesApi _novedades;

  Catalogs? _cached;

  @override
  Future<Catalogs> load({bool force = false}) async {
    final cached = _cached;
    if (cached != null && !force) return cached;

    // One failing catalog must not take the other two down with it: a missing
    // name degrades to "Materia 12", a thrown failure blanks the screen.
    var complete = true;
    Future<List<T>> orEmpty<T>(Future<List<T>> request) =>
        request.catchError((Object _) {
          complete = false;
          return <T>[];
        });
    final results = await Future.wait([
      orEmpty(_academic.courses()),
      orEmpty(_academic.subjects()),
      orEmpty(_novedades.types()),
    ]);

    final catalogs = Catalogs(
      courses: {for (final c in results[0] as List<Course>) c.id: c},
      subjects: {for (final s in results[1] as List<CourseSubject>) s.id: s},
      novedadTypes: {for (final t in results[2] as List<NovedadType>) t.id: t},
    );
    // N-36: a partial result is used once but never kept. Cached, a single
    // failed request left the whole session showing every novedad as
    // «Novedad · Baja» and courses without names.
    if (complete) _cached = catalogs;
    return catalogs;
  }

  @override
  void invalidate() => _cached = null;
}
