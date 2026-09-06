/// Connection settings for the Eyes School API (FastAPI on Azure App Service).
///
/// The base URL can be overridden at build time for a dev flavor:
/// `flutter run --dart-define=EYESCHOOL_API_BASE=https://localhost:8000`
abstract final class ApiConfig {
  static const _defaultBase =
      'https://apieyeschool-b7fudxavddh9hhah.canadacentral-01.azurewebsites.net';

  static const String host =
      String.fromEnvironment('EYESCHOOL_API_BASE', defaultValue: _defaultBase);

  static const String baseUrl = '$host/api/v1';

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 30);

  /// Page size used by every infinite-scroll list. The API exposes only
  /// `skip`/`limit` with no total, so `hasMore` is `page.length == limit`.
  static const int pageSize = 20;

  /// Page size used when warming full catalogs (students, courses, subjects).
  static const int catalogPageSize = 200;
}
