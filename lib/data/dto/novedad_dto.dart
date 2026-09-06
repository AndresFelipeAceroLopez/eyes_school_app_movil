import '../../core/utils/json_x.dart';
import '../../domain/entities/novedad.dart';
import '../../domain/value_objects/severity.dart';

/// `TipoNovedadOut` → [NovedadType].
abstract final class NovedadTypeMapper {
  static NovedadType fromJson(Json json) => NovedadType(
        id: asInt(json['id_tipo_novedad']),
        name: asString(json['nombre_tipo']),
        severity: NovedadSeverity.parse(asStringOrNull(json['nivel_gravedad'])),
        requiresAction: asBool(json['requiere_accion']),
        active: asBool(json['activo'], fallback: true),
        description: asStringOrNull(json['descripcion']),
      );
}

/// `NovedadOut` → [Novedad].
///
/// The severity is a property of the *type*, so it is resolved from the
/// catalog rather than read off the row: that is where the institution
/// configures it.
abstract final class NovedadMapper {
  static Novedad fromJson(
    Json json, {
    required String Function(int typeId) typeName,
    required NovedadSeverity Function(int typeId) severityOf,
    String? studentName,
  }) {
    final typeId = asInt(json['id_tipo_novedad']);
    return Novedad(
      studentName: studentName ?? 'Estudiante ${asInt(json['id_estudiante'])}',
      title: typeName(typeId),
      severity: severityOf(typeId),
      novedadId: asInt(json['id_novedad']),
      studentId: asInt(json['id_estudiante']),
      typeId: typeId,
      description: asString(json['descripcion']),
      action: asStringOrNull(json['accion_tomada']),
      date: asDate(json['fecha']),
      status: NovedadStatus.parse(asStringOrNull(json['estado'])),
    );
  }

  /// `NovedadCreate`.
  static Json createPayload({
    required int studentId,
    required int typeId,
    required DateTime date,
    required String description,
    required int registeredBy,
    String? action,
  }) {
    return <String, dynamic>{
      'id_estudiante': studentId,
      'id_tipo_novedad': typeId,
      'fecha': toApiDate(date),
      'descripcion': description,
      'registrado_por': registeredBy,
      if (action != null && action.isNotEmpty) 'accion_tomada': action,
    };
  }
}
