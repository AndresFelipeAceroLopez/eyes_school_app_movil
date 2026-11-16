// CP-ACE-088 (observación): con las notificaciones bloqueadas, el padre lo ve
// en su perfil y puede ir a activarlas.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eyes_school/features/notifications/presentation/notifications_off_notice.dart';

Future<void> _pump(
  WidgetTester tester, {
  required bool allowed,
  Future<void> Function()? open,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationsAllowedProvider.overrideWith((ref) async => allowed),
      ],
      child: MaterialApp(
        home: Scaffold(body: NotificationsOffNotice(openSettings: open)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('bloqueadas → aviso con «Activar», que abre los ajustes', (
    tester,
  ) async {
    var opened = 0;
    await _pump(tester, allowed: false, open: () async => opened++);

    expect(find.textContaining('notificaciones están desactivadas'), findsOne);
    await tester.tap(find.text('Activar'));
    await tester.pump();
    expect(opened, 1);
  });

  testWidgets('permitidas → no se muestra nada', (tester) async {
    await _pump(tester, allowed: true);

    expect(find.textContaining('desactivadas'), findsNothing);
    expect(find.text('Activar'), findsNothing);
  });
}
