import 'package:flutter/services.dart' show appFlavor;

/// Connection settings for the Eyes School API (FastAPI on Azure App Service).
///
/// The Android flavor picks the API (MC-02): `prod` talks to production and
/// `qa` (`com.eyesschoolqa.qa2`, QA Firebase project) to the QA API. A
/// `--dart-define=EYESCHOOL_API_BASE=...` still overrides both, for local work.
abstract final class ApiConfig {
  static const _defaultBase =
      'https://api-eyesschool-hrf2gsg7hyf9dacq.westus3-01.azurewebsites.net';

  static const _qaBase =
      'https://apieyeschool-q-g4hfgrgvepbecacc.chilecentral-01.azurewebsites.net';

  static const String _override = String.fromEnvironment('EYESCHOOL_API_BASE');

  /// The API host for a build of [flavor] (`null` when built without one).
  static String hostFor(String? flavor) {
    if (_override.isNotEmpty) return _override;
    return flavor == 'qa' ? _qaBase : _defaultBase;
  }

  static String get host => hostFor(appFlavor);

  static String get baseUrl => '$host/api/v1';

  /// The QA flavor is a separate app (other package, other Firebase project).
  static bool get isQaBuild => appFlavor == 'qa';

  /// GitHub repository (`owner/name`) whose releases feed the OTA update.
  /// QA can point it to a test repository with
  /// `--dart-define=EYESCHOOL_UPDATE_REPO=owner/repo` (APP-07).
  static const String updateRepo = String.fromEnvironment(
    'EYESCHOOL_UPDATE_REPO',
    defaultValue: 'AndresFelipeAceroLopez/eyes_school_app_movil',
  );

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 30);

  /// Page size used by every infinite-scroll list. The API exposes only
  /// `skip`/`limit` with no total, so `hasMore` is `page.length == limit`.
  static const int pageSize = 20;

  /// Page size used when warming full catalogs (students, courses, subjects).
  static const int catalogPageSize = 200;
}
