import 'dart:convert';

import 'package:dio/dio.dart';

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
    for (final entry in routes.entries) {
      if (options.path.endsWith(entry.key)) {
        final body = entry.value(options);
        return ResponseBody.fromString(
          jsonEncode(body),
          200,
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
