import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../domain/failures/app_failure.dart';
import '../storage/token_storage.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';
import 'retry_interceptor.dart';

/// Builds the single [Dio] the whole app talks through.
///
/// Interceptor order matters: auth first (so it can refresh and replay),
/// retry next (idempotent GETs), and the error translator last because it
/// rejects, which ends the chain.
Dio buildDio({
  required TokenStorage tokens,
  required Future<void> Function() onSessionExpired,
}) {
  final options = BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    headers: {'Accept': 'application/json'},
  );
  final dio = Dio(options);

  // A client with no interceptors, used to replay a request after a token
  // refresh and to retry an idempotent GET. It borrows the main client's
  // transport *at call time*, so swapping the adapter (a proxy, a pinned
  // certificate, a test's scripted transport) keeps applying everywhere.
  Dio bare() => Dio(options)..httpClientAdapter = dio.httpClientAdapter;

  dio.interceptors.add(AuthInterceptor(
    tokens: tokens,
    onSessionExpired: onSessionExpired,
    bareDio: bare,
  ));
  dio.interceptors.add(RetryInterceptor(bareDio: bare));
  dio.interceptors.add(const ErrorInterceptor());

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        request: false,
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: false,
        logPrint: (o) => debugPrint(_redact(o.toString())),
      ),
    );
  }

  return dio;
}

/// Never let a bearer token reach the console.
String _redact(String line) =>
    line.replaceAll(RegExp(r'Bearer [A-Za-z0-9._\-]+'), 'Bearer ***');

/// Unwraps the [AppFailure] that [ErrorInterceptor] attached, so call sites
/// can `try { ... } on AppFailure catch (e)` without knowing about Dio.
Never rethrowAsFailure(Object error, StackTrace stackTrace) {
  if (error is AppFailure) Error.throwWithStackTrace(error, stackTrace);
  if (error is DioException && error.error is AppFailure) {
    Error.throwWithStackTrace(error.error! as AppFailure, stackTrace);
  }
  Error.throwWithStackTrace(const UnexpectedFailure(), stackTrace);
}
