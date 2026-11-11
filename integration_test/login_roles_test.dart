// APP-INF-2 · Flujo 1 · CP-SIS-066 (PR-06).
// Inicio de sesión de cada rol con su inicio cargado (verifica BE-03): cada
// rol llega a su inicio y no queda ningún bloque en estado de error
// («Reintentar»).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final roles = <String, (String, String)>{
    'administrador': (qaAdmin, 'Gestión'),
    'docente': (qaDocente, 'Clases'),
    'estudiante': (qaEstudiante, 'Horario'),
    'padre': (qaPadre, 'Hijos'),
  };

  roles.forEach((rol, data) {
    final (email, navLabel) = data;
    testWidgets('CP-SIS-066 · $rol llega a su inicio con los datos cargados', (
      tester,
    ) async {
      requireDefines([email]);
      await startApp(tester);
      await login(tester, email, qaPassword);

      // Pestaña propia del rol (CP-SIS-070: solo los módulos del rol).
      expect(find.text(navLabel), findsWidgets);

      await settleFor(tester, const Duration(seconds: 8));
      expect(tester.takeException(), isNull);
      expect(
        find.text('Reintentar'),
        findsNothing,
        reason: 'El inicio de $rol quedó con un bloque en error',
      );
    });
  });
}
