import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Injects `Authorization: Bearer <access_token>` and transparently refreshes
/// an expired access token on the first `401`.
///
/// Ten requests firing at once must produce **one** refresh, not ten: the
/// in-flight refresh is held in [_refreshing] and every other 401 awaits it.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._tokens,
    required this._onSessionExpired,
    required this._bareDio,
  });

  /// Endpoints that must never carry a (possibly expired) bearer token and
  /// must never trigger a refresh loop.
  static const _publicPaths = {
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/forgot-password',
    '/auth/reset-password',
  };

  final TokenStorage _tokens;
  final Future<void> Function() _onSessionExpired;

  /// Builds an interceptor-free client that still shares the main client's
  /// transport. Refreshing and replaying must not re-enter this interceptor,
  /// but they must go out over the same adapter — otherwise a proxy, a pinned
  /// certificate or a test's scripted transport silently stops applying.
  final Dio Function() _bareDio;

  Future<_RefreshResult>? _refreshing;

  bool _isPublic(RequestOptions options) =>
      _publicPaths.any((p) => options.path.endsWith(p));

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options)) {
      final token = await _tokens.readAccessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final options = err.requestOptions;

    final shouldRefresh = response?.statusCode == 401 &&
        !_isPublic(options) &&
        options.extra['retried'] != true;

    if (!shouldRefresh) return handler.next(err);

    final result = await _refreshAccessToken();
    if (result.sessionOver) await _onSessionExpired();
    final token = result.accessToken;
    if (token == null) return handler.next(err);

    try {
      options.extra['retried'] = true;
      options.headers['Authorization'] = 'Bearer $token';
      final retried = await _bareDio().fetch<dynamic>(options);
      handler.resolve(retried);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Refreshes at most once at a time; concurrent 401s await the same future.
  Future<_RefreshResult> _refreshAccessToken() {
    return _refreshing ??= _performRefresh().whenComplete(() => _refreshing = null);
  }

  Future<_RefreshResult> _performRefresh() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null) return const _RefreshResult.sessionOver();
    try {
      final response = await _bareDio().post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final access = response.data?['access_token'] as String?;
      if (access == null) return const _RefreshResult.sessionOver();
      await _tokens.save(accessToken: access);
      return _RefreshResult.renewed(access);
    } on DioException catch (e) {
      // A network blip must not destroy a valid session: only an explicit
      // rejection of the refresh token counts as "session over".
      final status = e.response?.statusCode;
      final rejected = status == 401 || status == 403 || status == 422;
      return rejected ? const _RefreshResult.sessionOver() : const _RefreshResult.unavailable();
    }
  }
}

class _RefreshResult {
  const _RefreshResult.renewed(String token)
      : accessToken = token,
        sessionOver = false;

  /// The refresh token itself was rejected: the user has to log in again.
  const _RefreshResult.sessionOver()
      : accessToken = null,
        sessionOver = true;

  /// The refresh could not be attempted (no network). The session is kept and
  /// the original error surfaces as a `NetworkFailure`.
  const _RefreshResult.unavailable()
      : accessToken = null,
        sessionOver = false;

  final String? accessToken;
  final bool sessionOver;
}
