// CP-ACE-058 (observación): el padre veía la nota vieja hasta recargar a mano.
// Al cambiar de pestaña con conexión, las pantallas de datos vuelven a
// consultar la API sin perder lo que ya mostraban.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eyes_school/core/domain/repositories.dart';
import 'package:eyes_school/features/academic/domain/grade.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/repository_providers.dart';

class _CountingAcademic implements AcademicRepository {
  int calls = 0;

  @override
  Future<List<Grade>> gradesForStudent(
    int studentId, {
    int? period,
    int? subjectId,
  }) async {
    calls++;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('el pulso de recarga vuelve a pedir las notas', () async {
    final repo = _CountingAcademic();
    final container = ProviderContainer(
      overrides: [academicRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    const args = (studentId: 2, period: 1);
    final sub = container.listen(gradesForStudentProvider(args), (_, _) {});
    addTearDown(sub.close);

    await container.read(gradesForStudentProvider(args).future);
    expect(repo.calls, 1);

    // Leer otra vez sin el pulso no vuelve a la API (caché de la pantalla).
    await container.read(gradesForStudentProvider(args).future);
    expect(repo.calls, 1);

    container.read(dataRefreshProvider.notifier).state++;
    await container.read(gradesForStudentProvider(args).future);
    expect(repo.calls, 2);
  });
}
