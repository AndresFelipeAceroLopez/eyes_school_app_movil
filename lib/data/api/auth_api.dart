import 'package:dio/dio.dart';

import '../dto/auth_dto.dart';
import 'api_client.dart';

/// `/api/v1/auth` — the eight operations the app consumes.
class AuthApi {
  const AuthApi(this._client);

  final ApiClient _client;

  Future<TokenPairDto> login({required String correo, required String password}) async {
    final json = await _client.post(
      '/auth/login',
      body: {'correo': correo, 'password': password},
    );
    return TokenPairDto.fromJson(json);
  }

  Future<MeDto> me() async => MeDto.fromJson(await _client.getObject('/auth/me'));

  Future<void> register(Map<String, dynamic> payload) =>
      _client.post('/auth/register', body: payload);

  /// Fire-and-forget on the caller's side: the local session must be cleared
  /// whether or not the server accepts the invalidation.
  Future<void> logout(String refreshToken) =>
      _client.post('/auth/logout', body: {'refresh_token': refreshToken});

  Future<void> forgotPassword(String correo) =>
      _client.post('/auth/forgot-password', body: {'correo': correo});

  Future<void> resetPassword({required String token, required String newPassword}) =>
      _client.post('/auth/reset-password', body: {
        'token': token,
        'new_password': newPassword,
      });

  Future<void> uploadAvatar(String filePath) async {
    final data = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    await _client.upload('/auth/me/avatar', data);
  }

  Future<List<RolDto>> roles() => _client.getList('/roles', RolDto.fromJson);
}
