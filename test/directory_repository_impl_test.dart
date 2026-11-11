import 'package:dio/dio.dart';
import 'package:eyes_school/features/academic/data/academic_api.dart';
import 'package:eyes_school/features/auth/domain/app_user.dart';
import 'package:eyes_school/features/directory/data/catalog_repository_impl.dart';
import 'package:eyes_school/features/directory/data/directory_repository_impl.dart';
import 'package:eyes_school/features/directory/data/people_api.dart';
import 'package:eyes_school/features/directory/data/student_catalog.dart';
import 'package:eyes_school/features/directory/domain/role.dart';
import 'package:eyes_school/features/novedades/data/novedades_api.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_store.dart';
import 'support/scripted_api.dart';

/// The person cards are assembled from up to four endpoints. What matters is
/// that a missing piece degrades the card instead of failing it, and that the
/// joins (student ↔ user ↔ course ↔ guardians) land on the right person.
void main() {
  Map<String, Object? Function(RequestOptions)> school() => {
    '/cursos': (_) => [
      {
        'id_curso': 1,
        'nombre_curso': '10A',
        'grado': '10',
        'jornada': 'mañana',
        'ano': 2026,
      },
    ],
    '/materias': (_) => [
      {
        'id_materia': 11,
        'nombre_materia': 'Matemáticas',
        'codigo_materia': 'MAT',
      },
    ],
    '/tipos-novedad': (_) => [],
    '/usuarios/101': (_) => _user(101, 'Ana', 'Mora', role: 2),
    '/usuarios/201': (_) =>
        _user(201, 'Carlos', 'Mora', role: 4, phone: '3001234567'),
    '/usuarios/301': (_) => _user(301, 'Luisa', 'Pérez', role: 1),
    '/estudiantes/7': (_) => {
      'id_estudiante': 7,
      'id_usuario': 101,
      'codigo_estudiante': 'EST007',
      'estado': 'Activo',
      'id_curso_actual': 1,
    },
    '/estudiantes/8': (_) => {
      'id_estudiante': 8,
      'id_usuario': 999,
      'codigo_estudiante': 'EST008',
      'estado': 'Retirado',
      'primer_nombre': 'Beto',
      'primer_apellido': 'Gil',
    },
    '/estudiantes': (_) => [
      _student(7, 'EST007', 'Ana', 'Mora'),
      _student(8, 'EST008', 'Beto', 'Gil', status: 'Retirado'),
      _student(9, 'EST-009', 'Ana', 'Zapata'),
    ],
    '/padres': (_) => [
      {
        'id_padre': 1,
        'id_usuario': 201,
        'id_estudiante': 7,
        'parentesco': 'Padre',
        'nombre_estudiante': 'Ana Mora',
      },
      {
        'id_padre': 2,
        'id_usuario': 202,
        'id_estudiante': 7,
        'parentesco': 'Madre',
      },
      {
        'id_padre': 3,
        'id_usuario': 203,
        'id_estudiante': 9,
        'parentesco': 'Tía',
      },
    ],
    '/profesores/5/especializaciones': (_) => [
      {'id_especializacion': 1, 'nombre_especializacion': 'Álgebra'},
      {'id_especializacion': 2, 'nombre_especializacion': 'Geometría'},
    ],
    '/profesores/5': (_) => _teacher(5, user: 301),
    '/profesores/6': (_) =>
        _teacher(6, user: 999, status: 'Inactivo', first: 'Raúl', last: 'Díaz'),
    '/profesores': (_) => [
      _teacher(6, user: 999, first: 'Raúl', last: 'Díaz'),
      _teacher(5, user: 301, first: 'Luisa', last: 'Pérez'),
      _teacher(4, user: 998),
    ],
    '/asignaciones': (_) => [
      {'id_asignacion': 1, 'id_profesor': 5, 'id_curso': 1, 'id_materia': 11},
      {'id_asignacion': 2, 'id_profesor': 5, 'id_curso': 1, 'id_materia': 11},
      {'id_asignacion': 3, 'id_profesor': 5, 'id_curso': 2, 'id_materia': 11},
    ],
  };

  DirectoryRepositoryImpl repositoryOver(
    Map<String, Object? Function(RequestOptions)> routes,
  ) {
    final client = scriptedClient(
      ScriptedAdapter(routes, onUnmatched: notFound),
    );
    final academic = AcademicApi(client);
    final people = PeopleApi(client);
    return DirectoryRepositoryImpl(
      people: people,
      academic: academic,
      catalogs: CatalogRepositoryImpl(
        academic: academic,
        novedades: NovedadesApi(client),
      ),
      students: StudentCatalog(api: people, store: MemoryStore()),
    );
  }

  group('ficha del estudiante', () {
    test('une estudiante, usuario, curso y acudientes', () async {
      final card = await repositoryOver(school()).studentProfile(7);

      expect(card, isNotNull);
      expect(card!.name, 'Ana Mora');
      expect(card.role, Role.student);
      expect(card.grade, '10A');
      expect(card.jornada, 'Mañana');
      expect(card.document, 'CC 101');
      expect(card.guardians.map((g) => '${g.name} (${g.relation})'), [
        'Carlos Mora (Padre)',
        'Acudiente 2 (Madre)',
      ]);
      expect(card.guardians.first.phone, '3001234567');
    });

    test(
      'sin usuario ni curso la ficha usa los datos del estudiante',
      () async {
        final card = await repositoryOver(school()).studentProfile(8);

        expect(card!.name, 'Beto Gil');
        expect(card.status, AccountStatus.inactive);
        expect(card.grade, isNull);
        expect(card.document, isNull);
      },
    );

    test('un estudiante que no existe devuelve null', () async {
      expect(await repositoryOver(school()).studentProfile(404), isNull);
      expect(await repositoryOver(school()).userById(404), isNull);
    });

    test(
      'si /padres falla la ficha sale sin acudientes en vez de fallar',
      () async {
        final routes = school()..remove('/padres');

        final card = await repositoryOver(routes).studentProfile(7);

        expect(card!.guardians, isEmpty);
      },
    );
  });

  group('ficha del docente', () {
    test('lista sus especializaciones y sus cursos sin repetir', () async {
      final repository = repositoryOver(school());

      final card = await repository.teacherProfile(5);
      final courses = await repository.coursesOfTeacher(5);

      expect(card!.name, 'Luisa Pérez');
      expect(card.subject, 'Álgebra · Geometría');
      expect(card.status, AccountStatus.active);
      expect(courses, ['Matemáticas · 10A', 'Matemáticas · Curso 2']);
    });

    test(
      'sin usuario ni especializaciones usa el título y el nombre del profesor',
      () async {
        final card = await repositoryOver(school()).teacherProfile(6);

        expect(card!.name, 'Raúl Díaz');
        expect(card.subject, 'Licenciado');
        expect(card.status, AccountStatus.inactive);
        expect(await repositoryOver(school()).teacherProfile(404), isNull);
      },
    );
  });

  group('listas del directorio', () {
    test(
      'los docentes se ordenan y el código reemplaza un nombre vacío',
      () async {
        final teachers = await repositoryOver(school()).teachers();

        expect(teachers.map((t) => t.name), [
          'Luisa Pérez',
          'PROF4',
          'Raúl Díaz',
        ]);
      },
    );

    test('los acudientes muestran el parentesco con el estudiante', () async {
      final guardians = await repositoryOver(school()).guardians();

      expect(
        guardians.map((g) => g.subject),
        containsAll(['Padre de Ana Mora', 'Madre', 'Tía']),
      );
      expect(guardians.first.name, 'Acudiente 2');
    });

    test(
      'la búsqueda de estudiantes funciona sobre el catálogo local',
      () async {
        final repository = repositoryOver(school());

        final byName = await repository.searchStudents('ana');
        final byCourse = await repository.searchStudents('', courseId: 1);

        expect(byName.map((s) => s.name), ['Ana Mora', 'Ana Zapata']);
        expect(byName.first.grade, '10A');
        expect(byCourse.map((s) => s.code), ['EST007', 'EST008']);
      },
    );
  });
}

Map<String, dynamic> _user(
  int id,
  String first,
  String last, {
  required int role,
  String? phone,
}) => {
  'id_usuario': id,
  'tipo_documento': 'CC',
  'numero_documento': '$id',
  'primer_nombre': first,
  'primer_apellido': last,
  'correo': '${first.toLowerCase()}@eyes.edu.co',
  'telefono': ?phone,
  'id_rol': role,
  'estado': true,
};

Map<String, dynamic> _student(
  int id,
  String code,
  String first,
  String last, {
  String status = 'Activo',
}) => {
  'id_estudiante': id,
  'id_usuario': 100 + id,
  'codigo_estudiante': code,
  'estado': status,
  'id_curso_actual': id < 9 ? 1 : 2,
  'primer_nombre': first,
  'primer_apellido': last,
};

Map<String, dynamic> _teacher(
  int id, {
  required int user,
  String status = 'Activo',
  String? first,
  String? last,
}) => {
  'id_profesor': id,
  'id_usuario': user,
  'codigo_profesor': 'PROF$id',
  'titulo': 'Licenciado',
  'nivel_estudios': 'Profesional',
  'estado': status,
  'primer_nombre': ?first,
  'primer_apellido': ?last,
};
