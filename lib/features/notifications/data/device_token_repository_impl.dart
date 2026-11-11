import 'package:eyes_school/core/network/api_client.dart';
import 'package:eyes_school/features/notifications/domain/device_token_repository.dart';

/// `DispositivoCreate` requires `token_fcm` (10–512 characters) and
/// `plataforma` (`android`, `ios` or `web`). The app ships on Android only.
class DeviceTokenRepositoryImpl implements DeviceTokenRepository {
  DeviceTokenRepositoryImpl(this._client, {this.platform = 'android'});

  final ApiClient _client;
  final String platform;

  @override
  Future<void> register(String token) => _client.post(
        '/dispositivos',
        body: {'token_fcm': token, 'plataforma': platform},
      );

  @override
  Future<void> unregister(String token) =>
      _client.delete('/dispositivos/${Uri.encodeComponent(token)}');
}
