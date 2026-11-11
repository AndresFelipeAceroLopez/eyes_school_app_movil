// IT-APP-04 · APP-08 · Registro del dispositivo en la API (PR-05).
//
// Contrato REAL de la API de QA (/openapi.json, esquema DispositivoCreate,
// 10/11/2026): POST /dispositivos exige `token_fcm` (10–512 caracteres) Y
// `plataforma` (android | ios | web). La planeación solo menciona
// {"token_fcm": ...}; con solo ese campo la API responde 422.
// Baja: DELETE /dispositivos/{token_fcm}.
//
// NOMBRES PROPUESTOS POR QA (la planeación solo define la interfaz
// DeviceTokenRepository con register/unregister): implementación
// `DeviceTokenRepositoryImpl(ApiClient)` en
// lib/features/notifications/data/device_token_repository_impl.dart.
//
// Antes de la corrección: FALLA (no compila). Después de APP-08: pasa.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eyes_school/core/network/api_client.dart';
import 'package:eyes_school/features/notifications/data/device_token_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/scripted_api.dart';

const _token = 'token-fcm-de-prueba-0123456789';

void main() {
  late ScriptedAdapter adapter;
  late DeviceTokenRepositoryImpl repo;

  setUp(() {
    adapter = ScriptedAdapter({
      '/dispositivos': (_) => {'token_fcm': _token, 'plataforma': 'android'},
      '/dispositivos/$_token': (_) => null,
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://qa.invalid/api/v1'))
      ..httpClientAdapter = adapter;
    repo = DeviceTokenRepositoryImpl(ApiClient(dio));
  });

  test(
    'IT-APP-04 · register envía POST /dispositivos con token_fcm y plataforma',
    () async {
      await repo.register(_token);

      final post = adapter.sent.singleWhere((o) => o.method == 'POST');
      expect(post.path, endsWith('/dispositivos'));
      final body = post.data is String
          ? jsonDecode(post.data as String)
          : post.data;
      expect(body, {'token_fcm': _token, 'plataforma': 'android'});
    },
  );

  test('IT-APP-04 · unregister envía DELETE /dispositivos/{token}', () async {
    await repo.unregister(_token);

    final delete = adapter.sent.singleWhere((o) => o.method == 'DELETE');
    expect(delete.path, endsWith('/dispositivos/$_token'));
  });
}
