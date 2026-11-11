// APP-INF-2 · Flujo 5 · CP-SIS-097 (PR-06).
// Registro de padre vinculado (comportamiento por diseño): se registra por
// pasos, inicia sesión y ve los datos del estudiante vinculado.
//
// Crea una cuenta real en QA. Postcondición: el admin la elimina (QA lo hace
// por la API con el correo que imprime la prueba).
// QA_LINK_STUDENT_ID: id del estudiante a vincular (QA propuso 2, Juan Pérez,
// que tiene notas, asistencia y novedades; P-09 sigue abierta para DS-02).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';

const _linkStudentId = String.fromEnvironment('QA_LINK_STUDENT_ID');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'CP-SIS-097 · el padre registrado en la app ve a su hijo vinculado',
    (tester) async {
      requireDefines([_linkStudentId]);
      final ts = DateTime.now().millisecondsSinceEpoch.toString();
      final email = 'qa.cpsis097.$ts@example.com';
      debugPrint('CP-SIS-097 correo creado: $email');

      await startApp(tester);
      await tester.tap(find.text('Regístrate'));
      await waitFor(tester, find.text('Continuar'));

      // Paso 1 · identidad (tipo de documento CC por defecto).
      var fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '79${ts.substring(ts.length - 8)}');
      await tester.enterText(fields.at(1), 'QA');
      await tester.enterText(fields.at(3), 'Registro097');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.ensureVisible(find.text('Continuar'));
      await tester.pump();
      await tester.tap(find.text('Continuar'));
      await settleFor(tester, const Duration(seconds: 1));

      // Paso 2 · contacto (CA-PBI17.1: avanza por pasos).
      fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), email);
      await tester.enterText(fields.at(3), 'Colegio#2026');
      await tester.enterText(fields.at(4), 'Colegio#2026');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.ensureVisible(find.text('Continuar'));
      await tester.pump();
      await tester.tap(find.text('Continuar'));
      await settleFor(tester, const Duration(seconds: 1));

      // Paso 3 · rol padre, estudiante vinculado y parentesco.
      await tester.ensureVisible(find.text('Padre / Acudiente'));
      await tester.tap(find.text('Padre / Acudiente'));
      await tester.pump();
      fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), _linkStudentId);
      await tester.enterText(fields.at(1), 'Tutor');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.ensureVisible(find.text('Crear cuenta').last);
      await tester.tap(find.text('Crear cuenta').last);

      // Paso 5: confirmación visual de cuenta creada.
      await waitFor(tester, find.text('Cuenta creada'));
      await tester.tap(find.text('Entendido'));
      await waitFor(tester, find.text('Bienvenido'));

      // Pasos 6 y 7: inicia sesión y ve los datos de su hijo.
      await login(tester, email, 'Colegio#2026');
      expect(find.text('Hijos'), findsOneWidget);
      await settleFor(tester, const Duration(seconds: 6));
      expect(tester.takeException(), isNull);
      expect(find.text('Reintentar'), findsNothing);
    },
  );
}
