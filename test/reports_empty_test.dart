// CP-ACE-097: sin reportes, la app lo dice (QA tiene 4 reportes y vaciarlos
// exigiría borrar datos del backend; la pantalla se prueba con la lista vacía).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eyes_school/features/reports/presentation/reports_screen.dart';
import 'package:eyes_school/providers/data_providers.dart';

void main() {
  testWidgets('lista vacía → «Sin reportes generados»', (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [reportesProvider.overrideWith((ref) async => const [])],
        child: const MaterialApp(home: ReportsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sin reportes generados'), findsOneWidget);
    expect(find.text('Descargar'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
