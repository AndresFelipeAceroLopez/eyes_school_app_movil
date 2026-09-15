import 'package:eyes_school/core/utils/json_x.dart';
import 'package:eyes_school/features/attendance/domain/attendance_record.dart';
import 'package:eyes_school/features/attendance/domain/attendance.dart';

/// `AsistenciaOut` → [AttendanceRecord].
///
/// The wire spellings live in the domain value objects (`Suspensión` keeps its
/// accent); this file only moves JSON across the boundary.
abstract final class AttendanceMapper {
  static AttendanceRecord fromJson(Json json) => AttendanceRecord(
        id: asInt(json['id_asistencia']),
        studentId: asInt(json['id_estudiante']),
        date: asDate(json['fecha']) ?? DateTime.now(),
        state: AttendanceState.parse(asStringOrNull(json['estado'])),
        registeredBy: asInt(json['registrado_por']),
        kind: json['tipo'] == null
            ? null
            : AttendanceKind.parse(asStringOrNull(json['tipo'])),
        observation: asStringOrNull(json['observacion']),
        qrCode: asStringOrNull(json['codigo_qr']),
        registeredAt: asDate(json['fecha_registro']),
      );

  /// `AsistenciaCreate`. `registrado_por` is supplied by the client (the API
  /// does not derive it from the JWT), so it is always the signed-in user.
  static Json createPayload({
    required int studentId,
    required DateTime date,
    required AttendanceState state,
    required int registeredBy,
    AttendanceKind? kind,
    String? observation,
  }) {
    return <String, dynamic>{
      'id_estudiante': studentId,
      'fecha': toApiDate(date),
      'estado': state.label,
      'registrado_por': registeredBy,
      if (kind != null) 'tipo': kind.wire,
      if (observation != null && observation.isNotEmpty) 'observacion': observation,
    };
  }
}

/// [PendingAttendance] ⇄ the JSON kept in the offline queue's file.
abstract final class PendingAttendanceMapper {
  static PendingAttendance fromJson(Json json) => PendingAttendance(
        localId: asInt(json['local_id']),
        studentId: asInt(json['id_estudiante']),
        studentName: asString(json['nombre']),
        date: asDate(json['fecha']) ?? DateTime.now(),
        state: AttendanceState.parse(asStringOrNull(json['estado'])),
        kind: AttendanceKind.parse(asStringOrNull(json['tipo'])),
        registeredBy: asInt(json['registrado_por']),
        createdAt: asDate(json['creado_en']) ?? DateTime.now(),
        qrCode: asStringOrNull(json['codigo_qr']),
        observation: asStringOrNull(json['observacion']),
        attempts: asInt(json['intentos']),
        lastError: asStringOrNull(json['ultimo_error']),
        sync: SyncState.values.firstWhere(
          (s) => s.name == asString(json['sync']),
          orElse: () => SyncState.pending,
        ),
        remoteId: asIntOrNull(json['id_asistencia']),
        nextAttemptAt: asDate(json['proximo_intento']),
      );

  static Json toJson(PendingAttendance item) => <String, dynamic>{
        'local_id': item.localId,
        'id_estudiante': item.studentId,
        'nombre': item.studentName,
        'fecha': toApiDate(item.date),
        'estado': item.state.label,
        'tipo': item.kind.wire,
        'registrado_por': item.registeredBy,
        'creado_en': item.createdAt.toIso8601String(),
        if (item.qrCode != null) 'codigo_qr': item.qrCode,
        if (item.observation != null) 'observacion': item.observation,
        'intentos': item.attempts,
        if (item.lastError != null) 'ultimo_error': item.lastError,
        'sync': item.sync.name,
        if (item.remoteId != null) 'id_asistencia': item.remoteId,
        if (item.nextAttemptAt != null)
          'proximo_intento': item.nextAttemptAt!.toIso8601String(),
      };
}
