import 'package:eyes_school/core/utils/json_x.dart';
import 'package:eyes_school/features/attendance/domain/attendance_record.dart';

/// `UsuarioOut`.
class UsuarioDto {
  const UsuarioDto({
    required this.idUsuario,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.primerNombre,
    required this.primerApellido,
    required this.estado,
    required this.idRol,
    this.segundoNombre,
    this.segundoApellido,
    this.genero,
    this.direccion,
    this.correo,
    this.telefono,
    this.fotoPerfil,
    this.nombreRol,
    this.fechaRegistro,
    this.ultimoAcceso,
  });

  factory UsuarioDto.fromJson(Json json) {
    final rol = json['rol'];
    return UsuarioDto(
      idUsuario: asInt(json['id_usuario']),
      tipoDocumento: asString(json['tipo_documento']),
      numeroDocumento: asString(json['numero_documento']),
      primerNombre: asString(json['primer_nombre']),
      primerApellido: asString(json['primer_apellido']),
      estado: asBool(json['estado'], fallback: true),
      idRol: asInt(json['id_rol']),
      segundoNombre: asStringOrNull(json['segundo_nombre']),
      segundoApellido: asStringOrNull(json['segundo_apellido']),
      genero: asStringOrNull(json['genero']),
      direccion: asStringOrNull(json['direccion']),
      correo: asStringOrNull(json['correo']),
      telefono: asStringOrNull(json['telefono']),
      fotoPerfil: asStringOrNull(json['foto_perfil']),
      nombreRol: rol is Map ? asStringOrNull(rol['nombre_rol']) : null,
      fechaRegistro: asDate(json['fecha_registro']),
      ultimoAcceso: asDate(json['ultimo_acceso']),
    );
  }

  final int idUsuario;
  final String tipoDocumento;
  final String numeroDocumento;
  final String primerNombre;
  final String primerApellido;
  final bool estado;
  final int idRol;
  final String? segundoNombre;
  final String? segundoApellido;
  final String? genero;
  final String? direccion;
  final String? correo;
  final String? telefono;
  final String? fotoPerfil;
  final String? nombreRol;
  final DateTime? fechaRegistro;
  final DateTime? ultimoAcceso;

  String get nombreCompleto => joinNames([
        primerNombre,
        segundoNombre,
        primerApellido,
        segundoApellido,
      ]);
}

/// `EstudianteOut`.
class EstudianteDto {
  const EstudianteDto({
    required this.idEstudiante,
    required this.idUsuario,
    required this.codigoEstudiante,
    required this.estado,
    this.idCursoActual,
    this.fechaIngreso,
    this.primerNombre,
    this.segundoNombre,
    this.primerApellido,
    this.segundoApellido,
  });

  factory EstudianteDto.fromJson(Json json) => EstudianteDto(
        idEstudiante: asInt(json['id_estudiante']),
        idUsuario: asInt(json['id_usuario']),
        codigoEstudiante: asString(json['codigo_estudiante']),
        estado: asString(json['estado'], fallback: 'Activo'),
        idCursoActual: asIntOrNull(json['id_curso_actual']),
        fechaIngreso: asDate(json['fecha_ingreso']),
        primerNombre: asStringOrNull(json['primer_nombre']),
        segundoNombre: asStringOrNull(json['segundo_nombre']),
        primerApellido: asStringOrNull(json['primer_apellido']),
        segundoApellido: asStringOrNull(json['segundo_apellido']),
      );

  /// The identity the QR catalog stores and a scan resolves against.
  StudentIdentity toIdentity() => StudentIdentity(
        studentId: idEstudiante,
        userId: idUsuario,
        code: codigoEstudiante,
        status: estado,
        courseId: idCursoActual,
        firstName: [primerNombre, segundoNombre]
            .where((p) => p != null && p.isNotEmpty)
            .join(' '),
        lastName: [primerApellido, segundoApellido]
            .where((p) => p != null && p.isNotEmpty)
            .join(' '),
      );

  final int idEstudiante;
  final int idUsuario;
  final String codigoEstudiante;
  final String estado;
  final int? idCursoActual;
  final DateTime? fechaIngreso;
  final String? primerNombre;
  final String? segundoNombre;
  final String? primerApellido;
  final String? segundoApellido;

  /// `EstudianteOut` carries the names only on some endpoints; when it does
  /// not, the caller joins against `/usuarios/{id}`.
  String get nombreCompleto => joinNames([
        primerNombre,
        segundoNombre,
        primerApellido,
        segundoApellido,
      ]);

  bool get activo => estado.toLowerCase() == 'activo';

}

/// [StudentIdentity] ⇄ the compact rows the on-disk QR catalog keeps. Short
/// keys keep a thousand-student cache small enough to parse instantly.
abstract final class StudentIdentityMapper {
  static Json toJson(StudentIdentity student) => <String, dynamic>{
        'id': student.studentId,
        'u': student.userId,
        'c': student.code,
        'e': student.status,
        if (student.courseId != null) 'k': student.courseId,
        if (student.firstName != null) 'n': student.firstName,
        if (student.lastName != null) 'a': student.lastName,
      };

  static StudentIdentity fromJson(Json json) => StudentIdentity(
        studentId: asInt(json['id']),
        userId: asInt(json['u']),
        code: asString(json['c']),
        status: asString(json['e'], fallback: 'Activo'),
        courseId: asIntOrNull(json['k']),
        firstName: asStringOrNull(json['n']),
        lastName: asStringOrNull(json['a']),
      );
}

/// `ProfesorOut`.
class ProfesorDto {
  const ProfesorDto({
    required this.idProfesor,
    required this.idUsuario,
    required this.codigoProfesor,
    required this.titulo,
    required this.nivelEstudios,
    required this.estado,
    this.primerNombre,
    this.primerApellido,
  });

  factory ProfesorDto.fromJson(Json json) => ProfesorDto(
        idProfesor: asInt(json['id_profesor']),
        idUsuario: asInt(json['id_usuario']),
        codigoProfesor: asString(json['codigo_profesor']),
        titulo: asString(json['titulo']),
        nivelEstudios: asString(json['nivel_estudios']),
        estado: asString(json['estado'], fallback: 'Activo'),
        primerNombre: asStringOrNull(json['primer_nombre']),
        primerApellido: asStringOrNull(json['primer_apellido']),
      );

  final int idProfesor;
  final int idUsuario;
  final String codigoProfesor;
  final String titulo;
  final String nivelEstudios;
  final String estado;
  final String? primerNombre;
  final String? primerApellido;

  String get nombreCompleto => joinNames([primerNombre, primerApellido]);
}

/// `PadreOut` — a 1:1 link between a guardian account and one student.
class PadreDto {
  const PadreDto({
    required this.idPadre,
    required this.idUsuario,
    required this.idEstudiante,
    required this.parentesco,
    this.ocupacion,
    this.nombreEstudiante,
    this.documentoEstudiante,
  });

  factory PadreDto.fromJson(Json json) => PadreDto(
        idPadre: asInt(json['id_padre']),
        idUsuario: asInt(json['id_usuario']),
        idEstudiante: asInt(json['id_estudiante']),
        parentesco: asString(json['parentesco']),
        ocupacion: asStringOrNull(json['ocupacion']),
        nombreEstudiante: asStringOrNull(json['nombre_estudiante']),
        documentoEstudiante: asStringOrNull(json['documento_estudiante']),
      );

  final int idPadre;
  final int idUsuario;
  final int idEstudiante;
  final String parentesco;
  final String? ocupacion;
  final String? nombreEstudiante;
  final String? documentoEstudiante;
}

/// `AdministradorOut` — read-only in mobile, to show `cargo` on the profile.
class AdministradorDto {
  const AdministradorDto({
    required this.idAdministrador,
    required this.idUsuario,
    required this.cargo,
    required this.nivelAcceso,
    required this.estado,
  });

  factory AdministradorDto.fromJson(Json json) => AdministradorDto(
        idAdministrador: asInt(json['id_administrador']),
        idUsuario: asInt(json['id_usuario']),
        cargo: asString(json['cargo']),
        nivelAcceso: asString(json['nivel_acceso']),
        estado: asString(json['estado'], fallback: 'Activo'),
      );

  final int idAdministrador;
  final int idUsuario;
  final String cargo;
  final String nivelAcceso;
  final String estado;
}

/// `EspecializacionOut`.
class EspecializacionDto {
  const EspecializacionDto({required this.idEspecializacion, required this.nombre});

  factory EspecializacionDto.fromJson(Json json) => EspecializacionDto(
        idEspecializacion: asInt(json['id_especializacion']),
        nombre: asString(json['nombre_especializacion']),
      );

  final int idEspecializacion;
  final String nombre;
}

/// Joins the name parts the API splits across four nullable columns.
String joinNames(List<String?> parts) =>
    parts.where((p) => p != null && p.trim().isNotEmpty).map((p) => p!.trim()).join(' ');
