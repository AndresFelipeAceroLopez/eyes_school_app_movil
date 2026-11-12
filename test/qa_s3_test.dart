// Defectos encontrados en la ronda S3 de QA (12/11/2026), cada uno con la
// prueba que fallaba antes de su corrección.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/core/network/dio_client.dart';
import 'package:eyes_school/core/storage/token_storage.dart';
import 'package:eyes_school/features/directory/domain/role.dart';
import 'package:eyes_school/features/directory/presentation/qr_scan_screen.dart';
import 'package:eyes_school/features/splash/splash_screen.dart';
import 'package:eyes_school/providers/repository_providers.dart';
import 'package:eyes_school/providers/session_provider.dart';

import 'support/scripted_api.dart';

const _github =
    'https://api.github.com/repos/AndresFelipeAceroLopez/eyes_school_app_movil/releases/latest';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('N-29 · el token de la sesión no sale hacia otros dominios', () {
    late ScriptedAdapter adapter;
    late Dio dio;
    var refreshes = 0;
    var expired = 0;

    setUp(() {
      refreshes = 0;
      expired = 0;
      FlutterSecureStorage.setMockInitialValues({
        'eyeschool.auth.access_token': 'token-de-la-sesion',
        'eyeschool.auth.refresh_token': 'refresh-de-la-sesion',
      });
      adapter = ScriptedAdapter({
        '/releases/latest': (_) =>
            const ScriptedResponse(401, {'message': 'Bad credentials'}),
        '/auth/refresh': (_) {
          refreshes++;
          return {'access_token': 'token-renovado'};
        },
        '/auth/me': (_) => {'id_usuario': 1},
      });
      dio = buildDio(
        tokens: TokenStorage(),
        onSessionExpired: () async => expired++,
      )..httpClientAdapter = adapter;
    });

    test('una URL absoluta a GitHub no lleva Authorization', () async {
      await expectLater(dio.get<dynamic>(_github), throwsA(anything));

      final github = adapter.sent.where((o) => o.uri.host == 'api.github.com');
      expect(github, isNotEmpty);
      for (final request in github) {
        expect(request.headers.containsKey('Authorization'), isFalse);
      }
    });

    test('un 401 de GitHub no renueva ni cierra la sesión', () async {
      await expectLater(dio.get<dynamic>(_github), throwsA(anything));

      expect(refreshes, 0);
      expect(expired, 0);
      expect(
        adapter.requested.where((p) => p.endsWith('/auth/refresh')),
        isEmpty,
      );
    });

    test('las peticiones a la API siguen llevando el token', () async {
      await dio.get<dynamic>('/auth/me');

      final me = adapter.sent.last;
      expect(me.headers['Authorization'], 'Bearer token-de-la-sesion');
    });
  });

  group('N-27 · el docente abre sus pendientes desde el escáner', () {
    test('docente → ruta dentro de su propia rama', () {
      expect(pendingRouteFor(Role.teacher), '/teacher/qr/pendientes');
    });

    test('administrador → su ruta de siempre', () {
      expect(pendingRouteFor(Role.admin), '/admin/qr/pendientes');
    });
  });

  group('N-28 · abrir la app sin red no cierra la sesión', () {
    late ScriptedAdapter adapter;
    late ProviderContainer container;

    Future<void> settle() async {
      for (
        var i = 0;
        i < 500 && container.read(sessionProvider).isLoading;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({
        'eyeschool.auth.access_token': 'token-de-la-sesion',
        'eyeschool.auth.refresh_token': 'refresh-de-la-sesion',
      });
      // Sin rutas: toda petición falla como una conexión caída.
      adapter = ScriptedAdapter({});
      container = ProviderContainer(
        overrides: [
          dioProvider.overrideWith((ref) {
            final dio = buildDio(
              tokens: ref.watch(tokenStorageProvider),
              onSessionExpired: ref.watch(sessionExpiryProvider).fire,
            );
            dio.httpClientAdapter = adapter;
            return dio;
          }),
        ],
      );
      addTearDown(container.dispose);
      container.read(sessionProvider);
      await settle();
    });

    test('la sesión queda en error de red y los tokens se conservan', () async {
      final state = container.read(sessionProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<NetworkFailure>());
      expect(await TokenStorage().readAccessToken(), 'token-de-la-sesion');
      expect(await TokenStorage().readRefreshToken(), 'refresh-de-la-sesion');
    });

    test('«Reintentar» vuelve a consultar la API', () async {
      final before = adapter.requested.where((p) => p.endsWith('/auth/me'));
      final count = before.length;

      final retry = container.read(sessionProvider.notifier).retryRestore();
      expect(container.read(sessionProvider).isLoading, isTrue);
      await retry;

      expect(
        adapter.requested.where((p) => p.endsWith('/auth/me')).length,
        greaterThan(count),
      );
      expect(container.read(sessionProvider).hasError, isTrue);
    });

    testWidgets('el splash ofrece reintentar y cerrar sesión', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SplashScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.text('Iniciando sesión...'), findsNothing);
    });
  });
}
