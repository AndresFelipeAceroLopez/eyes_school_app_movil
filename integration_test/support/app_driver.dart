// APP-INF-2 · Utilidades comunes de los flujos de sistema (PR-06).
//
// Usuarios y contraseña entran SOLO por --dart-define (regla 9 de la
// planeación). Nombres de las variables propuestos por QA (P-11):
//   QA_PASSWORD, QA_USER_ADMIN, QA_USER_DOCENTE, QA_USER_ESTUDIANTE,
//   QA_USER_PADRE (padre de un hijo, DS-01), QA_USER_PADRE_2HIJOS (DS-03).
// La API se elige con EYESCHOOL_API_BASE (URL de QA sin /api/v1).
import 'package:eyes_school/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const qaPassword = String.fromEnvironment('QA_PASSWORD');
const qaAdmin = String.fromEnvironment('QA_USER_ADMIN');
const qaDocente = String.fromEnvironment('QA_USER_DOCENTE');
const qaEstudiante = String.fromEnvironment('QA_USER_ESTUDIANTE');
const qaPadre = String.fromEnvironment('QA_USER_PADRE');
const qaPadre2Hijos = String.fromEnvironment('QA_USER_PADRE_2HIJOS');

void requireDefines(List<String> values) {
  if (qaPassword.isEmpty || values.any((v) => v.isEmpty)) {
    fail('Faltan --dart-define de usuarios o QA_PASSWORD');
  }
}

/// Arranca la app desde cero: sin sesión guardada.
Future<void> startApp(WidgetTester tester) async {
  try {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  } catch (_) {
    // Igual que main.dart: sin Firebase la app sigue funcionando.
  }
  await const FlutterSecureStorage().deleteAll();
  await tester.pumpWidget(const ProviderScope(child: EyeSchoolApp()));
  await waitFor(tester, find.text('Bienvenido'));
}

/// Bombea cuadros hasta que aparezca [finder] o venza [timeout]. No usa
/// pumpAndSettle porque la mascota animada nunca deja de animarse.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 40),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('No apareció $finder en ${timeout.inSeconds} s');
}

/// Deja correr la app [duration] (cargas de red) sin esperar a que se quede quieta.
Future<void> settleFor(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> login(WidgetTester tester, String email, String password) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await tester.tap(find.text('Entrar'));
  await waitFor(tester, find.text('Inicio'));
}
