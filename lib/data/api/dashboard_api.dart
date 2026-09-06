import '../../domain/entities/dashboard.dart';
import '../dto/dashboard_dto.dart';
import 'api_client.dart';

/// `/dashboard/{rol}`. There is deliberately no admin dashboard: the API does
/// not expose one and the mobile admin is a hallway tool, not a control panel.
class DashboardApi {
  const DashboardApi(this._client);

  final ApiClient _client;

  Future<TeacherDashboard> teacher() async =>
      DashboardMapper.teacher(await _client.getObject('/dashboard/docente'));

  Future<StudentDashboard> student() async =>
      DashboardMapper.student(await _client.getObject('/dashboard/estudiante'));

  Future<GuardianDashboard> guardian() async =>
      DashboardMapper.guardian(await _client.getObject('/dashboard/padre'));
}
