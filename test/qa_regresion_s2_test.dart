// Regresiones encontradas al repetir los casos en el emulador (S2, 12/11/2026).
import 'package:dio/dio.dart';
import 'package:eyes_school/core/errors/app_failure.dart';
import 'package:eyes_school/core/network/failure_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _respuesta(int status, Object? data) {
  final options = RequestOptions(path: '/auth/reset-password');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  test('N-25 · un 401 con detalle muestra el motivo de la API', () {
    final failure = FailureMapper.from(
      _respuesta(401, {
        'detail': 'El enlace de recuperación es inválido o expiró',
      }),
    );
    expect(failure, isA<UnauthorizedFailure>());
    expect(failure.message, 'El enlace de recuperación es inválido o expiró');
  });

  test('N-25 · un 401 sin detalle sigue siendo sesión expirada', () {
    final failure = FailureMapper.from(_respuesta(401, null));
    expect(failure.message, 'Tu sesión expiró. Ingresa de nuevo.');
  });
}
