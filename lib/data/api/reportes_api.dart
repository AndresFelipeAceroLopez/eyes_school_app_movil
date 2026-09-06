import '../../core/network/api_config.dart';
import '../../domain/entities/dashboard.dart';
import '../dto/reporte_dto.dart';
import 'api_client.dart';

/// `/reportes` — consumed read-only. Creating, uploading and changing the
/// state of a report stays in the web panel.
class ReportesApi {
  const ReportesApi(this._client);

  final ApiClient _client;

  Future<List<Report>> reports({
    int? adminId,
    int skip = 0,
    int limit = ApiConfig.pageSize,
  }) {
    return _client.getList('/reportes', ReportMapper.fromJson, query: {
      'id_administrador': adminId,
      'skip': skip,
      'limit': limit,
    });
  }

  /// Authenticated download, same mechanism as the report card.
  Future<void> downloadFile({
    required int reportId,
    required String savePath,
    void Function(int received, int total)? onProgress,
  }) {
    return _client.download(
      '/reportes/$reportId/archivo',
      savePath,
      onProgress: onProgress,
    );
  }
}
