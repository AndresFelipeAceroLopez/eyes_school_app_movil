import 'package:eyes_school/app.dart';
import 'package:eyes_school/core/network/dio_client.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/scripted_api.dart';

/// Reproduces the failure seen on a device: the session restores fine (the
/// login worked), but the endpoints the student home needs are unreachable.
///
/// The rule this pins down: a dead API degrades a screen, it never takes the
/// app down. Anything that reaches `tester.takeException()` here is a crash a
/// user would see as a red screen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The default test surface is 800x600, which is not a phone. Overflows that
  /// only bite on a real device have to fail here too.
  void usePhoneViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    addTearDown(tester.view.reset);
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'eyeschool.auth.access_token': 'token-de-prueba',
      'eyeschool.auth.refresh_token': 'refresh-de-prueba',
    });
  });

  /// `/auth/me` and `/estudiantes/me` answer; everything else is unreachable.
  ScriptedAdapter studentWithDeadApi() => ScriptedAdapter({
        '/auth/me': (_) => {
              'id_usuario': 42,
              'primer_nombre': 'Ana',
              'primer_apellido': 'Gómez',
              'correo': 'ana@eyesschool.edu.co',
              'nombre_rol': 'estudiante',
              'id_rol': 2,
              'estado': true,
            },
        '/estudiantes/me': (_) => {
              'id_estudiante': 7,
              'id_usuario': 42,
              'codigo_estudiante': 'EST007',
              'fecha_ingreso': '2024-02-01',
              'estado': 'Activo',
              'id_curso_actual': 3,
              'fecha_registro': '2024-02-01T08:00:00',
            },
      });

  Future<void> pumpApp(WidgetTester tester, ScriptedAdapter adapter) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioProvider.overrideWith((ref) {
            final dio = buildDio(
              tokens: ref.watch(tokenStorageProvider),
              onSessionExpired: ref.watch(sessionExpiryProvider).fire,
            );
            dio.httpClientAdapter = adapter;
            return dio;
          }),
        ],
        child: const EyeSchoolApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  testWidgets('la API caída no tumba el inicio del estudiante', (tester) async {
    final adapter = studentWithDeadApi();
    await pumpApp(tester, adapter);

    // Ninguna excepción debe escapar hacia el árbol de widgets.
    expect(tester.takeException(), isNull);

    // La sesión sobrevive: el saludo se pinta con lo que sí respondió.
    expect(find.textContaining('Ana'), findsWidgets);

    // Y lo que no se pudo cargar se muestra como error accionable, no en rojo.
    expect(find.text('Reintentar'), findsWidgets);
  });

  testWidgets('una API totalmente caída deja al usuario en el login, no en rojo',
      (tester) async {
    await pumpApp(tester, ScriptedAdapter(const {}));

    expect(tester.takeException(), isNull);
    expect(find.text('Bienvenido'), findsOneWidget);
  });
}
