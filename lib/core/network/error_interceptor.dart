import 'package:dio/dio.dart';

import 'package:eyes_school/core/network/failure_mapper.dart';
import 'package:eyes_school/core/errors/app_failure.dart';

/// Attaches the domain [AppFailure] to every transport error, so nothing above
/// the data layer has to know what a `DioException` is.
///
/// Runs last in the chain: it rejects, which ends the chain.
class ErrorInterceptor extends Interceptor {
  const ErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: FailureMapper.from(err),
        stackTrace: err.stackTrace,
      ),
    );
  }
}
