// IT-APP-05 · BE-08 · Salida sin entrada previa (PR-05).
//
// La respuesta es la REAL de la API de QA (10/11/2026): POST /asistencia con
// tipo «salida» para un estudiante sin entrada ese día →
//   400 {"detail": "No hay entrada registrada hoy para este estudiante"}
// Decisión del PO del 30/10/2026: la cola debe dejar ese registro como
// fallido con ese mensaje y no reintentarlo sin fin.
//
// Se prueba con la cola y el cliente reales de la app (AttendanceQueue +
// AttendanceApi) sobre ScriptedAdapter.
//
// Resultado de hoy: se ejecuta por primera vez (planeación: «Sin ejecutar»).
import 'package:eyes_school/core/network/dio_client.dart';
import 'package:eyes_school/core/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:eyes_school/core/network/api_client.dart';
import 'package:eyes_school/core/storage/local_store.dart';
import 'package:eyes_school/features/attendance/data/attendance_api.dart';
import 'package:eyes_school/features/attendance/data/attendance_queue.dart';
import 'package:eyes_school/features/attendance/domain/attendance.dart';
import 'package:eyes_school/features/attendance/domain/attendance_record.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/scripted_api.dart';

const _sinEntrada = 'No hay entrada registrada hoy para este estudiante';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'IT-APP-05 · un 400 «No hay entrada registrada hoy» queda fallido y no se reintenta',
    () async {
      var posts = 0;
      final adapter = ScriptedAdapter({
        '/asistencia': (o) {
          posts++;
          return const ScriptedResponse(400, {'detail': _sinEntrada});
        },
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
      final queue = AttendanceQueue(
        api: AttendanceApi(ApiClient(dio)),
        store: LocalStore(),
      );

      final outcome = await queue.enqueue(
        studentId: 5,
        studentName: 'Estudiante 5',
        date: DateTime(2026, 11, 10),
        state: AttendanceState.present,
        kind: AttendanceKind.exit,
        registeredBy: 1,
      );
      expect(outcome, EnqueueOutcome.queued);

      await queue.flush(force: true);

      expect(
        queue.failed,
        hasLength(1),
        reason: 'estado: ${queue.items.map((i) => i.sync)}',
      );
      expect(queue.failed.single.lastError, _sinEntrada);
      expect(queue.pendingCount, 0);

      // Otra pasada del sincronizador no lo vuelve a enviar.
      await queue.flush(force: true);
      expect(posts, 1);
    },
  );
}
