// CP-NF-006 (Accessibility Scanner en el POCO X7, 16/11/2026): el botón
// central de escanear no tenía etiqueta, las pestañas se leían igual que los
// títulos y había botones de menos de 48 dp.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eyes_school/core/widgets/app_bottom_nav.dart';

Widget _bar() => MaterialApp(
  home: Scaffold(
    body: const Text('Notas'),
    bottomNavigationBar: AppBottomNav(
      items: const [
        NavItem(icon: Icons.grid_view_rounded, label: 'Inicio'),
        NavItem(icon: Icons.menu_book_rounded, label: 'Clases'),
        NavItem(
          icon: Icons.qr_code_scanner_rounded,
          label: 'QR',
          semanticLabel: 'Escanear código QR',
        ),
        NavItem(icon: Icons.bar_chart_rounded, label: 'Notas'),
        NavItem(icon: Icons.person_rounded, label: 'Perfil'),
      ],
      currentIndex: 3,
      elevatedIndex: 2,
      onTap: (_) {},
    ),
  ),
);

void main() {
  testWidgets('el botón central tiene etiqueta y las pestañas se anuncian', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_bar());

    expect(find.bySemanticsLabel('Escanear código QR'), findsOneWidget);
    expect(find.bySemanticsLabel('Notas, pestaña'), findsOneWidget);
    expect(find.bySemanticsLabel('Perfil, pestaña'), findsOneWidget);
    // El título de la pantalla ya no comparte descripción con la pestaña.
    expect(find.bySemanticsLabel('Notas'), findsOneWidget);

    // TalkBack activa con la acción de toque: debe seguir existiendo.
    for (final label in ['Escanear código QR', 'Notas, pestaña']) {
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason: label,
      );
    }
    handle.dispose();
  });

  testWidgets('la barra cumple las guías de etiquetas y de tamaño de toque', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_bar());

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });
}
