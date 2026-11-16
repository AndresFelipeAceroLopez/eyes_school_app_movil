// N-31 (AB#122): una cuenta desactivada veía «Tu cuenta está pendiente de
// validación». La API manda el mismo `estado: false` para las dos situaciones,
// así que el texto tiene que ser cierto para ambas.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eyes_school/features/auth/domain/app_user.dart';
import 'package:eyes_school/features/auth/domain/session.dart';
import 'package:eyes_school/features/directory/domain/role.dart';
import 'package:eyes_school/features/errors/no_access_screen.dart';
import 'package:eyes_school/providers/session_provider.dart';

Future<void> _pump(WidgetTester tester, AppSession? session) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [currentSessionProvider.overrideWithValue(session)],
      child: const MaterialApp(home: NoAccessScreen()),
    ),
  );
}

AppSession _session(AccountStatus status) => AppSession(
  user: AppUser(
    userId: 1,
    name: 'Padre Prueba',
    email: 'padre@example.com',
    role: Role.parent,
    status: status,
  ),
);

void main() {
  testWidgets('cuenta inactiva: texto válido para pendiente y desactivada', (
    tester,
  ) async {
    await _pump(tester, _session(AccountStatus.inactive));

    expect(find.text('Cuenta inactiva'), findsOneWidget);
    expect(find.textContaining('no está activa'), findsOneWidget);
    expect(find.textContaining('pendiente de validación'), findsNothing);
    expect(find.text('Volver a mi inicio'), findsNothing);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('ruta de otro rol: «Sin acceso» y vuelta al inicio', (
    tester,
  ) async {
    await _pump(tester, _session(AccountStatus.active));

    expect(find.text('Sin acceso'), findsOneWidget);
    expect(find.text('Volver a mi inicio'), findsOneWidget);
  });
}
