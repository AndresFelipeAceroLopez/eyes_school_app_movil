import 'package:dio/dio.dart';

import '../../domain/failures/app_failure.dart';

/// Turns a transport failure into an [AppFailure].
///
/// This is the boundary: below it there are status codes and `DioException`s,
/// above it only the domain's vocabulary.
abstract final class FailureMapper {
  static bool isTransportFailure(DioException err) {
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        true,
      DioExceptionType.unknown => err.response == null,
      _ => false,
    };
  }

  static AppFailure from(DioException err) {
    if (err.type == DioExceptionType.cancel) {
      return const UnexpectedFailure('Solicitud cancelada.');
    }
    if (err.type == DioExceptionType.badCertificate) {
      return const NetworkFailure('No se pudo verificar el servidor.');
    }
    if (isTransportFailure(err)) {
      final slow = err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.sendTimeout ||
          err.type == DioExceptionType.receiveTimeout;
      return slow
          ? const NetworkFailure('La conexión tardó demasiado. Intenta de nuevo.')
          : const NetworkFailure();
    }

    final status = err.response?.statusCode ?? 0;
    final data = err.response?.data;

    if (status == 422) {
      final fields = _fieldErrors(data);
      return ValidationFailure(
        fields.values.isEmpty ? 'Revisa los datos ingresados.' : fields.values.first,
        fields,
      );
    }

    final detail = _detail(data);
    return switch (status) {
      401 => const UnauthorizedFailure(),
      403 => ForbiddenFailure(detail ?? 'No tienes permiso para esta acción.'),
      404 => NotFoundFailure(detail ?? 'No encontramos el recurso solicitado.'),
      409 => ConflictFailure(detail ?? 'El registro ya existe.'),
      >= 500 => const ServerFailure(),
      _ => UnexpectedFailure(detail ?? 'No pudimos completar la solicitud.'),
    };
  }

  /// FastAPI's `{"detail": "..."}`.
  static String? _detail(Object? data) {
    if (data is Map && data['detail'] is String) return data['detail'] as String;
    if (data is String && data.isNotEmpty && data.length < 200) return data;
    return null;
  }

  /// `HTTPValidationError` → `{campo: mensaje}`, keyed by the last segment of
  /// `loc`, which is the body field name (`loc: ["body", "correo"]`).
  static Map<String, String> _fieldErrors(Object? data) {
    final result = <String, String>{};
    if (data is! Map) return result;
    final detail = data['detail'];
    if (detail is! List) {
      final message = _detail(data);
      if (message != null) result['_'] = message;
      return result;
    }
    for (final item in detail) {
      if (item is! Map) continue;
      final loc = item['loc'];
      final message = item['msg']?.toString() ?? 'Valor inválido.';
      final field = (loc is List && loc.isNotEmpty) ? loc.last.toString() : '_';
      result.putIfAbsent(field, () => message);
    }
    return result;
  }
}
