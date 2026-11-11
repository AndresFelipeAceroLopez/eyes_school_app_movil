// IT-APP-01 · APP-03 · Mapeo de /padres/me/hijos (PR-05, CP-INT-075).
//
// Usa la respuesta REAL grabada de la API de QA (rosa.perez, DS-03):
// test/fixtures/api/padres_me_hijos.json, con dos hijos.
//
// Contrato de la planeación (APP-03, «Diseño»): entidad `LinkedChild`
// (id, name, document, relationship, courseId) en lib/features/directory/domain/
// y `HijoDto` con su mapper en people_dto.dart.
// NOMBRES PROPUESTOS POR QA (la planeación no los define): archivo
// `linked_child.dart` y método `HijoDto.toEntity()`.
//
// Va en un archivo propio, y no en dto_mapping_test.dart como dice la
// planeación, porque mientras no compile arrastraría a sus 20 pruebas.
//
// Antes de la corrección: FALLA (no compila). Después de APP-03: pasa.
import 'dart:convert';
import 'dart:io';

import 'package:eyes_school/features/directory/data/people_dto.dart';
import 'package:eyes_school/features/directory/domain/linked_child.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('IT-APP-01 · /padres/me/hijos con 2 elementos → 2 LinkedChild', () {
    final rows =
        (jsonDecode(
                  File(
                    'test/fixtures/api/padres_me_hijos.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<Map<String, dynamic>>();

    final List<LinkedChild> children = rows
        .map((j) => HijoDto.fromJson(j).toEntity())
        .toList();

    expect(children, hasLength(2));
    expect(children.map((c) => c.id), [1, 3]);
    expect(children.first.name, 'Sofía Rodríguez');
    expect(children.first.document, '20000001');
    expect(children.first.relationship, 'Madre');
    expect(children.first.courseId, 1);
    expect(children.last.relationship, 'Abuela');
    expect(children.last.courseId, 2);
  });
}
