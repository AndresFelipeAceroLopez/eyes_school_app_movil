// UT-APP-07 · APP-08 · Registro del token de notificaciones (PR-04).
//
// Contrato de la planeación (APP-08, «Diseño»):
//   - lib/features/notifications/domain/ con la interfaz DeviceTokenRepository,
//     métodos register(String token) y unregister(String token).
//   - PushNotificationService recibe por constructor el FirebaseMessaging y el
//     DeviceTokenRepository.
//   - Registra tras iniciar sesión y en cada onTokenRefresh; da de baja al
//     cerrar sesión; con el permiso negado no registra y no lanza.
//
// NOMBRES PROPUESTOS POR QA (la planeación no los define; el desarrollador
// puede cambiarlos y ajustar solo estas líneas):
//   - archivo device_token_repository.dart
//   - constructor con nombre: PushNotificationService(messaging:, deviceTokens:)
//   - onSignedIn() y onSignedOut()
//
// Antes de la corrección: FALLA (no compila; el servicio es un singleton que
// crea FirebaseMessaging.instance adentro). Después de APP-08: pasa.
import 'dart:async';

import 'package:eyes_school/features/notifications/data/push_notification_service.dart';
import 'package:eyes_school/features/notifications/domain/device_token_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

class _Settings extends Fake implements NotificationSettings {
  _Settings(this.authorizationStatus);
  @override
  final AuthorizationStatus authorizationStatus;
}

class _FakeMessaging extends Fake implements FirebaseMessaging {
  _FakeMessaging({this.status = AuthorizationStatus.authorized});

  final AuthorizationStatus status;
  final refresh = StreamController<String>.broadcast();
  String token = 'token-fcm-1';

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async => _Settings(status);

  @override
  Future<String?> getToken({
    String? serviceWorkerScriptPath,
    String? vapidKey,
  }) async => token;

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Future<void> deleteToken() async {}
}

class _RecordingTokens implements DeviceTokenRepository {
  final registered = <String>[];
  final unregistered = <String>[];

  @override
  Future<void> register(String token) async => registered.add(token);

  @override
  Future<void> unregister(String token) async => unregistered.add(token);
}

void main() {
  group('PushNotificationService (UT-APP-07)', () {
    test('registra el token después de iniciar sesión', () async {
      final tokens = _RecordingTokens();
      final service = PushNotificationService(
        messaging: _FakeMessaging(),
        deviceTokens: tokens,
      );

      await service.onSignedIn();

      expect(tokens.registered, ['token-fcm-1']);
    });

    test('vuelve a registrar cuando el token se renueva', () async {
      final messaging = _FakeMessaging();
      final tokens = _RecordingTokens();
      final service = PushNotificationService(
        messaging: messaging,
        deviceTokens: tokens,
      );

      await service.onSignedIn();
      messaging.refresh.add('token-fcm-2');
      await Future<void>.delayed(Duration.zero);

      expect(tokens.registered, ['token-fcm-1', 'token-fcm-2']);
    });

    test('con el permiso negado no registra y no lanza', () async {
      final tokens = _RecordingTokens();
      final service = PushNotificationService(
        messaging: _FakeMessaging(status: AuthorizationStatus.denied),
        deviceTokens: tokens,
      );

      await expectLater(service.onSignedIn(), completes);
      expect(tokens.registered, isEmpty);
    });

    test('da de baja el token al cerrar sesión', () async {
      final tokens = _RecordingTokens();
      final service = PushNotificationService(
        messaging: _FakeMessaging(),
        deviceTokens: tokens,
      );

      await service.onSignedIn();
      await service.onSignedOut();

      expect(tokens.unregistered, ['token-fcm-1']);
    });
  });
}
