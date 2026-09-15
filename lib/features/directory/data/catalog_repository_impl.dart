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
    final results = await Future.wait([
      _academic.courses().catchError((_) => <Course>[]),
      _academic.subjects().catchError((_) => <CourseSubject>[]),
      _novedades.types().catchError((_) => <NovedadType>[]),
    ]);

    return _cached = Catalogs(
      courses: {for (final c in results[0] as List<Course>) c.id: c},
      subjects: {for (final s in results[1] as List<CourseSubject>) s.id: s},
      novedadTypes: {for (final t in results[2] as List<NovedadType>) t.id: t},
    );
  }

  @override
  void invalidate() => _cached = null;
}
