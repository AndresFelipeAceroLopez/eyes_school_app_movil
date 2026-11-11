// UT-APP-08 · APP-07 · Actualizador OTA (PR-04).
//
// Contrato de la planeación (APP-07): UpdateService con Dio y ScriptedAdapter
//   - consulta /repos/AndresFelipeAceroLopez/eyes_school_app_movil/releases/latest
//   - versión publicada mayor → hasUpdate == true
//   - versión igual → hasUpdate == false
//   - sin red → hasUpdate == false sin excepción
//
// La plataforma se inyecta (`isAndroid`) para que la consulta se pruebe en el
// CI, que no corre en Android (regla 3 de la planeación).
//
// Antes de la corrección: FALLA (nombre viejo del repositorio y salida
// temprana por plataforma). Después de APP-07: pasa.
import 'package:dio/dio.dart';
import 'package:eyes_school/core/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'support/scripted_api.dart';

const _latestPath =
    '/repos/AndresFelipeAceroLopez/eyes_school_app_movil/releases/latest';

Map<String, Object?> _release(String tag) => {
  'tag_name': tag,
  'body': 'Notas de prueba',
  'assets': [
    {
      'name': 'eyes_school-$tag.apk',
      'browser_download_url': 'https://example.invalid/eyes_school-$tag.apk',
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'eyes_school',
      packageName: 'com.example.eyes_school',
      version: '1.0.1',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  (UpdateService, ScriptedAdapter) build(
    Map<String, Object? Function(RequestOptions)> routes,
  ) {
    final adapter = ScriptedAdapter(routes);
    final dio = Dio()..httpClientAdapter = adapter;
    return (UpdateService(dio, isAndroid: () => true), adapter);
  }

  group('UpdateService (UT-APP-08)', () {
    test('consulta el repositorio eyes_school_app_movil', () async {
      final (service, adapter) = build({
        _latestPath: (_) => _release('v1.0.1'),
      });
      await service.checkForUpdates();
      expect(adapter.requested, contains(endsWith(_latestPath)));
    });

    test('versión publicada mayor → hasUpdate', () async {
      final (service, _) = build({_latestPath: (_) => _release('v1.1.0')});
      final info = await service.checkForUpdates();
      expect(info.hasUpdate, isTrue);
      expect(info.latestVersion, '1.1.0');
    });

    test('versión igual → sin actualización', () async {
      final (service, _) = build({_latestPath: (_) => _release('v1.0.1')});
      final info = await service.checkForUpdates();
      expect(info.hasUpdate, isFalse);
    });

    test('sin red → sin actualización y sin excepción', () async {
      final (service, _) = build(const {});
      final info = await service.checkForUpdates();
      expect(info.hasUpdate, isFalse);
    });
  });
}
