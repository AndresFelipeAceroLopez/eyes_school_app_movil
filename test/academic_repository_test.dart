// IT-APP-06 · BE-19 · Boletín de un estudiante sin notas (PR-05).
//
// Respuesta REAL de la API de QA (10/11/2026):
//   GET /notas/estudiantes/4/boletin/pdf → 404
//   {"detail": "No hay datos disponibles para generar el boletín."}
// La app debe producir un AppFailure con ese texto exacto, que
// report_card_download.dart muestra al padre.
//
// Resultado de hoy: se ejecuta por primera vez (planeación: «Sin ejecutar»).
import 'dart:io';

import 'package:eyes_school/core/network/dio_client.dart';
import 'package:eyes_school/core/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/core/network/api_client.dart';
import 'package:eyes_school/features/academic/data/academic_api.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/scripted_api.dart';

const _sinDatos = 'No hay datos disponibles para generar el boletín.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'IT-APP-06 · un 404 del boletín produce AppFailure con el texto de la API',
    () async {
      final adapter = ScriptedAdapter({
        '/notas/estudiantes/4/boletin/pdf': (_) =>
            const ScriptedResponse(404, {'detail': _sinDatos}),
      });
      // Mismo cliente que la app (interceptores de autenticación, reintento y
      // traducción de errores); solo cambia el transporte.
      FlutterSecureStorage.setMockInitialValues({
        'eyeschool.auth.access_token': 't',
      });
      final dio = buildDio(
        tokens: TokenStorage(),
        onSessionExpired: () async {},
      )..httpClientAdapter = adapter;
      final api = AcademicApi(ApiClient(dio));
      final dir = await Directory.systemTemp.createTemp('boletin');
      addTearDown(() => dir.delete(recursive: true));

      await expectLater(
        api.downloadReportCard(
          studentId: 4,
          savePath: '${dir.path}/boletin.pdf',
        ),
        throwsA(
          isA<AppFailure>().having((f) => f.message, 'message', _sinDatos),
        ),
      );
    },
  );
}
