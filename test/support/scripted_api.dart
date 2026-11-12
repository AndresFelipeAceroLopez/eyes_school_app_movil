import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:eyes_school/core/network/api_client.dart';
import 'package:eyes_school/core/network/error_interceptor.dart';

/// A Dio adapter that answers from a script instead of the network, so a test
/// can reproduce exactly what a device sees: a 200 here, a dead connection
/// there.
class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.routes, {this.onUnmatched = _failConnection});

  /// Keyed by the request path (`/auth/me`), matched by `endsWith` so query
  /// strings and the `/api/v1` prefix do not have to be repeated.
  final Map<String, Object? Function(RequestOptions options)> routes;

  /// What happens to any path the script does not cover. Defaults to a dead
  /// connection, which is what an unreachable API looks like.
  final ResponseBody Function(RequestOptions options) onUnmatched;

  final List<String> requested = [];

  /// Each request as it was sent (method, path, body), for contract checks.
  final List<RequestOptions> sent = [];

  static ResponseBody _failConnection(RequestOptions options) {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'sin red en la prueba',
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requested.add(options.path);
    sent.add(options);
    for (final entry in routes.entries) {
      if (options.path.endsWith(entry.key)) {
        final result = entry.value(options);
        final status = result is ScriptedResponse ? result.status : 200;
        final body = result is ScriptedResponse ? result.body : result;
        return ResponseBody.fromString(
          jsonEncode(body),
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
    }
    return onUnmatched(options);
  }

  @override
  void close({bool force = false}) {}
}

/// A scripted answer with a status other than 200 (for example a FastAPI
/// `{"detail": "..."}` with 400 or 404). Routes that return anything else keep
/// answering 200, as before.
class ScriptedResponse {
  const ScriptedResponse(this.status, this.body);

  final int status;
  final Object? body;
}

/// What an endpoint the script does not list answers in a repository test:
/// a 404, so "not found" paths are exercised without the retry backoff a dead
/// connection would trigger.
ResponseBody notFound(RequestOptions options) => ResponseBody.fromString(
  jsonEncode({'detail': 'No encontrado'}),
  404,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

/// An [ApiClient] over [adapter], with the same failure translation as the
/// app's client but without auth or retries: repository tests are about
/// mapping and joins, not about the transport.
ApiClient scriptedClient(ScriptedAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
    ..httpClientAdapter = adapter
    ..interceptors.add(const ErrorInterceptor());
  return ApiClient(dio);
}
