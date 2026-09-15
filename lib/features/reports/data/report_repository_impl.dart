import 'package:eyes_school/core/network/api_config.dart';
import 'package:eyes_school/features/dashboard/domain/dashboard.dart';
import 'package:eyes_school/core/domain/repositories.dart';
import 'package:eyes_school/features/reports/data/reportes_api.dart';

class ReportRepositoryImpl implements ReportRepository {
  const ReportRepositoryImpl(this._api);

  final ReportesApi _api;

  @override
  Future<List<Report>> reports({int skip = 0, int limit = ApiConfig.pageSize}) async {
    final rows = await _api.reports(skip: skip, limit: limit);
    rows.sort((a, b) => (b.generatedAt ?? DateTime(2000))
        .compareTo(a.generatedAt ?? DateTime(2000)));
    return rows;
  }

  @override
  Future<void> downloadReport({
    required int reportId,
    required String savePath,
    void Function(int received, int total)? onProgress,
  }) {
    return _api.downloadFile(
      reportId: reportId,
      savePath: savePath,
      onProgress: onProgress,
    );
  }
}
