// UT-APP-03 · APP-04 · Formulario de restablecer contraseña (PR-04).
//
// Con «Colegio2026» (sin carácter especial) el formulario no debe llamar al
// repositorio. Doble con contador inyectado por `ProviderScope`.
//
// Antes de la corrección: FALLA (el validador solo exige 8 caracteres y el
// formulario se envía). Después de APP-04: pasa.
import 'package:eyes_school/core/domain/repositories.dart';
import 'package:eyes_school/features/auth/presentation/reset_password_screen.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountingAuthRepository extends Fake implements AuthRepository {
  int resets = 0;

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    resets++;
  }
}

void main() {
  Future<_CountingAuthRepository> fillAndSubmit(
    WidgetTester tester,
    String password,
  ) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    addTearDown(tester.view.reset);

    final repo = _CountingAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: ResetPasswordScreen(token: 'codigo-de-prueba'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3)); // código, nueva, confirmar
    await tester.enterText(fields.at(1), password);
    await tester.enterText(fields.at(2), password);

    final submit = find.text('Guardar contraseña');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('UT-APP-03 · «Colegio2026» no llega al repositorio', (
    tester,
  ) async {
    final repo = await fillAndSubmit(tester, 'Colegio2026');
    expect(repo.resets, 0);
  });

  testWidgets('control · «Colegio#2026» sí llega al repositorio', (
    tester,
  ) async {
    final repo = await fillAndSubmit(tester, 'Colegio#2026');
    expect(repo.resets, 1);
  });
}
