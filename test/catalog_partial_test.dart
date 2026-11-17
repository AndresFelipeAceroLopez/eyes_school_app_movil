// N-36: una falla momentánea al cargar los catálogos quedaba guardada toda la
// sesión: todas las novedades salían como «Novedad · Baja».
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eyes_school/features/academic/data/academic_api.dart';
import 'package:eyes_school/features/directory/data/catalog_repository_impl.dart';
import 'package:eyes_school/features/novedades/data/novedades_api.dart';

import 'support/scripted_api.dart';

void main() {
  test(
    'un catálogo incompleto no se guarda: la siguiente carga reintenta',
    () async {
      var typesUp = false;
      var typeCalls = 0;
      final adapter = ScriptedAdapter({
        '/cursos': (_) => <Object>[],
        '/materias': (_) => <Object>[],
        '/tipos-novedad': (RequestOptions _) {
          typeCalls++;
          if (!typesUp) {
            return const ScriptedResponse(503, {'detail': 'reiniciando'});
          }
          return [
            {
              'id_tipo_novedad': 1,
              'nombre': 'Conflicto entre pares',
              'nivel_gravedad': 'Alta',
            },
          ];
        },
      });
      final client = scriptedClient(adapter);
      final repo = CatalogRepositoryImpl(
        academic: AcademicApi(client),
        novedades: NovedadesApi(client),
      );

      final first = await repo.load();
      expect(first.novedadTypes, isEmpty);

      typesUp = true;
      final second = await repo.load();
      expect(typeCalls, 2);
      expect(second.novedadTypes, hasLength(1));

      // Completo, ya se guarda: no vuelve a pedirlo.
      await repo.load();
      expect(typeCalls, 2);
    },
  );
}
