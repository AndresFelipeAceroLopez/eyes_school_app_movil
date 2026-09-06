import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT pair persisted in the Keystore / Keychain. Never in SharedPreferences
/// and never in the local database.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _accessKey = 'eyeschool.auth.access_token';
  static const _refreshKey = 'eyeschool.auth.refresh_token';

  final FlutterSecureStorage _storage;

  /// Cached in memory so the interceptor does not hit the platform channel on
  /// every single request.
  String? _accessToken;
  String? _refreshToken;
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _accessToken = await _storage.read(key: _accessKey);
    _refreshToken = await _storage.read(key: _refreshKey);
    _loaded = true;
  }

  Future<String?> readAccessToken() async {
    await _ensureLoaded();
    return _accessToken;
  }

  Future<String?> readRefreshToken() async {
    await _ensureLoaded();
    return _refreshToken;
  }

  Future<bool> hasSession() async => (await readRefreshToken()) != null;

  Future<void> save({required String accessToken, String? refreshToken}) async {
    _accessToken = accessToken;
    await _storage.write(key: _accessKey, value: accessToken);
    if (refreshToken != null) {
      _refreshToken = refreshToken;
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
    _loaded = true;
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _loaded = true;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
