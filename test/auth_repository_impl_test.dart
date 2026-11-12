import 'package:dio/dio.dart';
import 'package:eyes_school/core/domain/repositories.dart';
import 'package:eyes_school/core/storage/token_storage.dart';
import 'package:eyes_school/features/academic/data/academic_api.dart';
import 'package:eyes_school/features/auth/data/auth_api.dart';
import 'package:eyes_school/features/auth/data/auth_repository_impl.dart';
import 'package:eyes_school/features/dashboard/data/dashboard_api.dart';
import 'package:eyes_school/features/directory/data/catalog_repository_impl.dart';
import 'package:eyes_school/features/directory/data/people_api.dart';
import 'package:eyes_school/features/directory/domain/role.dart';
import 'package:eyes_school/features/novedades/data/novedades_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/scripted_api.dart';

/// Sign-in ends in a per-role bootstrap that turns `/auth/me` into a session
/// every screen can address. A missing role profile must become a readable
/// warning, never a crash on the splash screen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<RequestOptions> writes;
  late TokenStorage tokens;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    tokens = TokenStorage();
    writes = [];
  });

  Map<String, dynamic> write(RequestOptions options) {
    writes.add(options);
    return <String, dynamic>{};
  }

  Map<String, Object? Function(RequestOptions)> api({required int role}) => {
    '/auth/login': (options) {
      writes.add(options);
      return {'access_token': 'acceso', 'refresh_token': 'refresco'};
    },
    '/auth/me': (_) => {
      'id_usuario': 42,
      'primer_nombre': 'Ana',
      'primer_apellido': 'Gómez',
      'correo': 'ana@eyes.edu.co',
      'nombre_rol': 'rol',
      'id_rol': role,
      'estado': true,
    },
    '/auth/logout': write,
    '/auth/forgot-password': write,
    '/auth/reset-password': write,
    '/auth/register': write,
    '/roles': (_) => [
      {'id_rol': 1, 'nombre_rol': 'Docente'},
      {'id_rol': 2, 'nombre_rol': 'Estudiante'},
    ],
    '/cursos': (_) => [
      {
        'id_curso': 3,
        'nombre_curso': '10A',
        'grado': '10',
        'jornada': 'tarde',
        'ano': 2026,
      },
    ],
    '/materias': (_) => [],
    '/tipos-novedad': (_) => [],
    '/estudiantes/me': (_) => {
      'id_estudiante': 7,
      'id_usuario': 42,
      'codigo_estudiante': 'EST007',
      'estado': 'Activo',
      'id_curso_actual': 3,
    },
    '/estudiantes/7': (_) => {
      'id_estudiante': 7,
      'id_usuario': 50,
      'codigo_estudiante': 'EST007',
      'id_curso_actual': 3,
    },
    '/dashboard/estudiante': (_) => {
      'periodo_actual': 3,
      'promedio_general': 4.1,
      'porcentaje_asistencia': 96.5,
    },
    '/dashboard/padre': (_) => {'periodo_actual': 3, 'novedades_pendientes': 1},
    '/padres/me': (_) => {
      'id_padre': 2,
      'id_usuario': 42,
      'id_estudiante': 7,
      'parentesco': 'Madre',
      'nombre_estudiante': 'Juan Gómez',
      'documento_estudiante': '1012',
    },
    '/profesores': (_) => [
      {
        'id_profesor': 9,
        'id_usuario': 41,
        'codigo_profesor': 'P9',
        'titulo': 'Lic.',
        'nivel_estudios': 'Pregrado',
      },
      {
        'id_profesor': 5,
        'id_usuario': 42,
        'codigo_profesor': 'P5',
        'titulo': 'Lic. Matemáticas',
        'nivel_estudios': 'Maestría',
      },
    ],
    '/administradores': (_) => [
      {
        'id_administrador': 1,
        'id_usuario': 42,
        'cargo': 'Coordinadora',
        'nivel_acceso': 'Total',
      },
    ],
    '/usuarios/42': (options) => options.method == 'PUT'
        ? write(options)
        : {
            'id_usuario': 42,
            'tipo_documento': 'CC',
            'numero_documento': '5555',
            'primer_nombre': 'Ana',
            'segundo_nombre': 'María',
            'primer_apellido': 'Gómez',
            'telefono': '3000000000',
            'direccion': 'Calle 1',
            'id_rol': role,
          },
  };

  AuthRepositoryImpl repositoryOver(
    Map<String, Object? Function(RequestOptions)> routes,
  ) {
    final client = scriptedClient(
      ScriptedAdapter(routes, onUnmatched: notFound),
    );
    return AuthRepositoryImpl(
      auth: AuthApi(client),
      people: PeopleApi(client),
      dashboard: DashboardApi(client),
      catalogs: CatalogRepositoryImpl(
        academic: AcademicApi(client),
        novedades: NovedadesApi(client),
      ),
      tokens: tokens,
    );
  }

  test('el login guarda los tokens antes de armar la sesión', () async {
    final repository = repositoryOver(api(role: 2));

    expect(await repository.hasStoredSession(), isFalse);
    await repository.signIn(email: '  ana@eyes.edu.co ', password: 'secreta');

    expect(writes.first.data, {
      'correo': 'ana@eyes.edu.co',
      'password': 'secreta',
    });
    expect(await tokens.readAccessToken(), 'acceso');
    expect(await repository.hasStoredSession(), isTrue);
  });

  test('el estudiante recibe su curso, jornada y periodo actual', () async {
    final session = await repositoryOver(api(role: 2)).restoreSession();

    expect(session.user.role, Role.student);
    expect(session.studentId, 7);
    expect(session.studentCode, 'EST007');
    expect(session.user.grade, '10A');
    expect(session.user.jornada, 'Tarde');
    expect(session.currentPeriod, 3);
    expect(session.user.average, 4.1);
    expect(session.bootstrapWarning, isNull);
  });

  test('un tablero caído no impide entrar al estudiante', () async {
    final routes = api(role: 2)..remove('/dashboard/estudiante');

    final session = await repositoryOver(routes).restoreSession();

    expect(session.studentId, 7);
    expect(session.currentPeriod, isNull);
  });

  test(
    'el docente se encuentra por su usuario cuando /profesores/me no existe',
    () async {
      final session = await repositoryOver(api(role: 1)).restoreSession();

      expect(session.user.role, Role.teacher);
      expect(session.teacherId, 5);
      expect(session.user.subject, 'Lic. Matemáticas');
    },
  );

  test('sin perfil de docente la sesión explica qué falta', () async {
    final routes = api(role: 1)..['/profesores'] = (_) => [];

    final session = await repositoryOver(routes).restoreSession();

    expect(session.teacherId, isNull);
    expect(session.bootstrapWarning, contains('perfil de docente'));
  });

  test('el acudiente queda vinculado a su hijo y al curso del hijo', () async {
    final session = await repositoryOver(api(role: 4)).restoreSession();

    expect(session.user.role, Role.parent);
    expect(session.parentId, 2);
    expect(session.childId, 7);
    expect(session.childName, 'Juan Gómez');
    expect(session.relationship, 'Madre');
    expect(session.courseId, 3);
    expect(session.subjectStudentId, 7);
  });

  test(
    'un acudiente sin vínculo ve un aviso en vez de una pantalla en blanco',
    () async {
      final routes = api(role: 4)..remove('/padres/me');

      final session = await repositoryOver(routes).restoreSession();

      expect(session.childId, isNull);
      expect(session.bootstrapWarning, isNotNull);
    },
  );

  test('el administrador muestra su cargo', () async {
    final session = await repositoryOver(api(role: 3)).restoreSession();

    expect(session.user.role, Role.admin);
    expect(session.user.subject, 'Coordinadora');
  });

  test(
    'el perfil completo y sus cambios usan /usuarios del propio usuario',
    () async {
      final repository = repositoryOver(api(role: 2));
      final session = await repository.restoreSession();

      final full = await repository.loadFullProfile(session.user);
      await repository.updateProfile(userId: 42, phone: '3111111111');
      await repository.changePassword(
        userId: 42,
        currentPassword: 'clave-actual',
        password: 'nueva-clave',
      );

      expect(full.name, 'Ana María Gómez');
      expect(full.document, 'CC 5555');
      expect(full.email, 'ana@eyes.edu.co');
      expect(writes.map((w) => w.data), [
        {'telefono': '3111111111'},
        // N-12 / BE-09: la API exige la contraseña actual.
        {'password': 'nueva-clave', 'password_actual': 'clave-actual'},
      ]);
    },
  );

  test(
    'registro, recuperación y roles hablan con los endpoints de auth',
    () async {
      final repository = repositoryOver(api(role: 2));

      await repository.register(
        const RegistrationRequest(
          documentType: 'TI',
          documentNumber: '1012',
          firstName: 'Juan',
          lastName: 'Gómez',
          roleId: 2,
          email: 'juan@eyes.edu.co',
          courseId: 3,
        ),
      );
      await repository.requestPasswordReset(' ana@eyes.edu.co ');
      await repository.resetPassword(token: 't0k3n', newPassword: 'otra-clave');
      final roles = await repository.availableRoles();

      expect(writes.map((w) => w.path), [
        '/auth/register',
        '/auth/forgot-password',
        '/auth/reset-password',
      ]);
      expect(writes[0].data, containsPair('id_curso_actual', 3));
      expect(writes[0].data, isNot(contains('segundo_nombre')));
      expect(writes[1].data, {'correo': 'ana@eyes.edu.co'});
      expect(writes[2].data, {'token': 't0k3n', 'new_password': 'otra-clave'});
      expect(roles.map((r) => r.name), ['Docente', 'Estudiante']);
    },
  );

  test('cerrar sesión borra los tokens aunque el servidor falle', () async {
    final routes = api(role: 2)..remove('/auth/logout');
    final repository = repositoryOver(routes);
    await repository.signIn(email: 'ana@eyes.edu.co', password: 'secreta');

    await repository.signOut();

    expect(await repository.hasStoredSession(), isFalse);
    expect(await tokens.readAccessToken(), isNull);
  });
}
