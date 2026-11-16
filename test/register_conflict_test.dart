// CP-ACE-011 (observación) y N-32: el 409 «El correo ya está registrado» se
// marca en el correo del paso 2, y al corregirlo el registro puede avanzar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eyes_school/core/network/dio_client.dart';
import 'package:eyes_school/features/auth/presentation/register_screen.dart';
import 'package:eyes_school/providers/repository_providers.dart';

import 'support/scripted_api.dart';

const _dup = 'El correo ya está registrado';

Future<void> _continue(WidgetTester tester, String label) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await tester.ensureVisible(find.text(label).last);
  await tester.pump();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('el 409 se asigna al campo que corresponde', () {
    expect(registrationConflictField(_dup), 'correo');
    expect(
      registrationConflictField('El documento ya está registrado'),
      'numero_documento',
    );
    expect(registrationConflictField('Otro conflicto'), isNull);
  });

  testWidgets('correo duplicado → vuelve al paso 2 marcado y, al corregirlo, '
      'deja avanzar', (tester) async {
    // Ancho de tablet: la fuente de pruebas de Flutter es más ancha que la
    // real y desborda el selector de documento a 390 dp (en el emulador no).
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(600 * 3, 1000 * 3);
    addTearDown(tester.view.reset);
    FlutterSecureStorage.setMockInitialValues({});
    final adapter = ScriptedAdapter({
      '/auth/register': (_) => const ScriptedResponse(409, {'detail': _dup}),
      '/cursos': (_) => <Object>[],
    });

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
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Paso 1 · identidad.
    var fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '7912345601');
    await tester.enterText(fields.at(1), 'QA');
    await tester.enterText(fields.at(3), 'Duplicado');
    await _continue(tester, 'Continuar');
    expect(find.text('Paso 2 de 3'), findsOneWidget);

    // Paso 2 · contacto con un correo ya usado.
    fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'roberto.diaz@gmail.com');
    await tester.enterText(fields.at(3), 'Colegio#2026');
    await tester.enterText(fields.at(4), 'Colegio#2026');
    await _continue(tester, 'Continuar');
    expect(find.text('Paso 3 de 3'), findsOneWidget);

    // Paso 3 · padre.
    await tester.ensureVisible(find.text('Padre / Acudiente'));
    await tester.tap(find.text('Padre / Acudiente'));
    await tester.pumpAndSettle();
    fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '74');
    await tester.enterText(fields.at(1), 'Tio');
    await _continue(tester, 'Crear cuenta');

    // Vuelve al paso del correo, con el error en el campo.
    expect(find.text('Paso 2 de 3'), findsOneWidget);
    expect(find.text(_dup), findsOneWidget);

    // N-32: con otro correo, «Continuar» avanza.
    fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'otro.correo@example.com');
    await _continue(tester, 'Continuar');
    expect(find.text('Paso 3 de 3'), findsOneWidget);
    expect(find.text(_dup), findsNothing);
  });
}
