/// Everything that can go wrong, expressed in the language of the domain.
///
/// This is the only error type the application and presentation layers know
/// about: `Dio`, HTTP status codes and JSON live below, in `data`.
sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The request was rejected field by field. [fieldErrors] maps a payload field
/// to its message so a form can paint the error on the right input.
class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, this.fieldErrors);

  final Map<String, String> fieldErrors;

  String? errorFor(String field) => fieldErrors[field];
}

class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([super.message = 'Tu sesión expiró. Ingresa de nuevo.']);
}

class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure([super.message = 'No tienes permiso para esta acción.']);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'No encontramos el recurso solicitado.']);
}

class ConflictFailure extends AppFailure {
  const ConflictFailure([super.message = 'El registro ya existe.']);
}

class ServerFailure extends AppFailure {
  const ServerFailure([super.message = 'El servidor no está disponible. Intenta más tarde.']);
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Sin conexión. Revisa tu red e intenta de nuevo.']);
}

class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure([super.message = 'No pudimos completar la solicitud.']);
}
