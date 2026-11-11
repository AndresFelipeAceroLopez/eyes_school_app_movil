// APP-INF-2 · Flujo 4 · CP-SIS-092 (PR-06).
// Padre de DS-03 (dos hijos): la pestaña Hijos lista a los dos.
// Antes de APP-03: FALLA (la app solo conoce un hijo).
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CP-SIS-092 · el padre de DS-03 ve a sus dos hijos', (
    tester,
  ) async {
    requireDefines([qaPadre2Hijos]);
    await startApp(tester);
    await login(tester, qaPadre2Hijos, qaPassword);

    await tester.tap(find.text('Hijos'));
    await settleFor(tester, const Duration(seconds: 6));

    expect(tester.takeException(), isNull);
    // Datos de QA del 10/11/2026: Sofía Rodríguez (id 1) y Santiago López (id 3).
    expect(find.textContaining('Sofía Rodríguez'), findsWidgets);
    expect(find.textContaining('Santiago López'), findsWidgets);
  });
}
