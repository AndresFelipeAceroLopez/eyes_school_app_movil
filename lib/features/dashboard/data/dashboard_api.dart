import 'package:eyes_school/features/dashboard/domain/dashboard.dart';
import 'package:eyes_school/features/dashboard/data/dashboard_dto.dart';
import 'package:eyes_school/core/network/api_client.dart';

/// `/dashboard/{rol}`. There is deliberately no admin dashboard: the API does
/// not expose one and the mobile admin is a hallway tool, not a control panel.
class DashboardApi {
  const DashboardApi(this._client);

  final ApiClient _client;

  Future<TeacherDashboard> teacher() async =>
      DashboardMapper.teacher(await _client.getObject('/dashboard/docente'));

  Future<StudentDashboard> student() async =>
      DashboardMapper.student(await _client.getObject('/dashboard/estudiante'));

  /// [studentId] picks which linked child the figures are about (APP-03);
  /// without it the API answers for the first one.
  Future<GuardianDashboard> guardian({int? studentId}) async =>
      DashboardMapper.guardian(await _client.getObject(
        '/dashboard/padre',
        query: {'id_estudiante': studentId},
      ));
}
