import 'package:dio/dio.dart';

import '../../data/network/failure_mapper.dart';

/// Retries **idempotent GETs only** when the transport flaked. Writes are
/// never retried here: `POST /asistencia` has no idempotency key, so an
/// automatic retry could duplicate a record. Attendance writes go through the
/// offline queue instead, which knows how to deduplicate.
///
/// Must sit before [ErrorInterceptor] in the chain, which rejects and so ends
/// the chain.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({required this._bareDio, this.maxAttempts = 2});

  final Dio Function() _bareDio;
  final int maxAttempts;

  static const _backoff = [Duration(milliseconds: 400), Duration(milliseconds: 1200)];

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final attempt = (options.extra['retryAttempt'] as int?) ?? 0;

    final retriable = options.method.toUpperCase() == 'GET' &&
        FailureMapper.isTransportFailure(err) &&
        attempt < maxAttempts;

    if (!retriable) return handler.next(err);

    await Future<void>.delayed(_backoff[attempt.clamp(0, _backoff.length - 1)]);
    options.extra['retryAttempt'] = attempt + 1;

    try {
      handler.resolve(await _bareDio().fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
