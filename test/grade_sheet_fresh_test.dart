// CP-ACE-060 (16/11/2026): tras guardar sin señal, la planilla se reabría con
// el error viejo («Sin conexión») aunque ya hubiera red, y podía mostrar notas
// más viejas que las del servidor. Ahora se consulta cada vez que se abre.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eyes_school/core/domain/repositories.dart';
import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/features/academic/domain/grade.dart';
import 'package:eyes_school/providers/data_providers.dart';
import 'package:eyes_school/providers/repository_providers.dart';

class _Sheet implements AcademicRepository {
  int calls = 0;
  bool online = false;

  @override
  Future<List<Grade>> gradeSheet({
    required int subjectId,
    required int period,
  }) async {
    calls++;
    if (!online) throw const NetworkFailure();
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test(
    'al reabrir la planilla se consulta de nuevo (no queda el error viejo)',
    () async {
      final repo = _Sheet();
      final container = ProviderContainer(
        overrides: [academicRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      const key = (subjectId: 1, period: 1);

      // Primera apertura, sin red: error.
      var sub = container.listen(gradeSheetProvider(key), (_, _) {});
      await expectLater(
        container.read(gradeSheetProvider(key).future),
        throwsA(isA<NetworkFailure>()),
      );
      sub.close();
      await Future<void>.delayed(Duration.zero); // se libera al cerrar

      // Vuelve la red y se reabre: consulta otra vez y ya no hay error.
      repo.online = true;
      sub = container.listen(gradeSheetProvider(key), (_, _) {});
      addTearDown(sub.close);
      await expectLater(
        container.read(gradeSheetProvider(key).future),
        completes,
      );
      expect(repo.calls, 2);
    },
  );
}
