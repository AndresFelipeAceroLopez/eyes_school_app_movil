import 'package:eyes_school/core/network/api_config.dart';
import 'package:eyes_school/core/utils/json_x.dart';
import 'package:eyes_school/features/attendance/domain/attendance_record.dart';
import 'package:eyes_school/features/attendance/domain/attendance.dart';
import 'package:eyes_school/features/attendance/data/attendance_dto.dart';
import 'package:eyes_school/core/network/api_client.dart';

/// `/asistencia` — the busiest module of the app.
class AttendanceApi {
  const AttendanceApi(this._client);

  final ApiClient _client;

  /// `fecha` filters server-side; course and shift are filtered on the client
  /// because the endpoint does not accept them.
  Future<List<AttendanceRecord>> list({
    int? studentId,
    DateTime? date,
    AttendanceKind? kind,
    int skip = 0,
    int limit = ApiConfig.pageSize,
  }) {
    return _client.getList('/asistencia', AttendanceMapper.fromJson, query: {
      'id_estudiante': studentId,
      'fecha': date == null ? null : toApiDate(date),
      'tipo': kind?.wire,
      'skip': skip,
      'limit': limit,
    });
  }

  Future<AttendanceRecord> create({
    required int studentId,
    required DateTime date,
    required AttendanceState state,
    required int registeredBy,
    AttendanceKind? kind,
    String? observation,
  }) async {
    final json = await _client.post(
      '/asistencia',
      body: AttendanceMapper.createPayload(
        studentId: studentId,
        date: date,
        state: state,
        registeredBy: registeredBy,
        kind: kind,
        observation: observation,
      ),
    );
    return AttendanceMapper.fromJson(json);
  }

  Future<AttendanceRecord> byId(int attendanceId) async =>
      AttendanceMapper.fromJson(await _client.getObject('/asistencia/$attendanceId'));

  Future<AttendanceRecord> update(
    int attendanceId, {
    AttendanceState? state,
    String? observation,
  }) async {
    final body = <String, dynamic>{
      if (state != null) 'estado': state.label,
      'observacion': ?observation,
    };
    final json = await _client.put('/asistencia/$attendanceId', body: body);
    return AttendanceMapper.fromJson(json);
  }

  Future<void> delete(int attendanceId) => _client.delete('/asistencia/$attendanceId');
}
