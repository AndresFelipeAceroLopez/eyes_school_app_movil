import '../../core/utils/json_x.dart';
import '../../domain/repositories/repositories.dart';

/// `TokenResponse` — the login payload.
class TokenPairDto {
  const TokenPairDto({required this.accessToken, required this.refreshToken});

  factory TokenPairDto.fromJson(Json json) => TokenPairDto(
        accessToken: asString(json['access_token']),
        refreshToken: asString(json['refresh_token']),
      );

  final String accessToken;
  final String refreshToken;
}

/// `MeResponse` — the source of truth for the signed-in user's role.
class MeDto {
  const MeDto({
    required this.idUsuario,
    required this.primerNombre,
    required this.primerApellido,
    required this.correo,
    required this.nombreRol,
    required this.idRol,
    required this.estado,
  });

  factory MeDto.fromJson(Json json) => MeDto(
        idUsuario: asInt(json['id_usuario']),
        primerNombre: asString(json['primer_nombre']),
        primerApellido: asString(json['primer_apellido']),
        correo: asStringOrNull(json['correo']),
        nombreRol: asString(json['nombre_rol']),
        idRol: asInt(json['id_rol']),
        estado: asBool(json['estado'], fallback: true),
      );

  final int idUsuario;
  final String primerNombre;
  final String primerApellido;
  final String? correo;
  final String nombreRol;
  final int idRol;

  /// `false` means the account is still awaiting validation by an admin.
  final bool estado;
}

/// `RolOut` — populates the role selector on the sign-up form.
class RolDto {
  const RolDto({required this.idRol, required this.nombreRol});

  factory RolDto.fromJson(Json json) => RolDto(
        idRol: asInt(json['id_rol']),
        nombreRol: asString(json['nombre_rol']),
      );

  final int idRol;
  final String nombreRol;
}

/// [RegistrationRequest] → `RegisterRequest`. One payload creates the user and
/// its role profile, which is why the role-specific fields are all optional.
abstract final class RegisterPayload {
  static Json from(RegistrationRequest request) => <String, dynamic>{
        'tipo_documento': request.documentType,
        'numero_documento': request.documentNumber,
        'primer_nombre': request.firstName,
        'primer_apellido': request.lastName,
        'id_rol': request.roleId,
        if (request.middleName != null) 'segundo_nombre': request.middleName,
        if (request.secondLastName != null) 'segundo_apellido': request.secondLastName,
        if (request.gender != null) 'genero': request.gender,
        if (request.address != null) 'direccion': request.address,
        if (request.email != null) 'correo': request.email,
        if (request.password != null) 'password': request.password,
        if (request.phone != null) 'telefono': request.phone,
        if (request.position != null) 'cargo': request.position,
        if (request.courseId != null) 'id_curso_actual': request.courseId,
        if (request.linkedStudentId != null)
          'id_estudiante_vinculado': request.linkedStudentId,
        if (request.relationship != null) 'parentesco': request.relationship,
        if (request.title != null) 'titulo': request.title,
        if (request.studyLevel != null) 'nivel_estudios': request.studyLevel,
      };
}
