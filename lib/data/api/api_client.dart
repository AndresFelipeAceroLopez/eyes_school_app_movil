import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';
import '../../core/utils/json_x.dart';

/// Thin typed wrapper over [Dio]. Every method funnels failures through
/// [rethrowAsFailure], so callers above this line only ever see the
/// `AppFailure` family.
class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  Dio get raw => _dio;

  Future<Json> getObject(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get<dynamic>(path, queryParameters: _clean(query));
      return _asObject(response.data);
    } catch (e, s) {
      rethrowAsFailure(e, s);
    }
  }

  Future<List<T>> getList<T>(
    String path,
    T Function(Json json) mapper, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<dynamic>(path, queryParameters: _clean(query));
      return asList(_asListPayload(response.data), mapper);
    } catch (e, s) {
      rethrowAsFailure(e, s);
    }
  }

  Future<Json> post(String path, {Object? body, Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: body,
        queryParameters: _clean(query),
      );
      return _asObject(response.data);
    } catch (e, s) {
      rethrowAsFailure(e, s);
    }
  }

  Future<Json> put(String path, {Object? body}) async {
    try {
      final response = await _dio.put<dynamic>(path, data: body);
      return _asObject(response.data);
    } catch (e, s) {
      rethrowAsFailure(e, s);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete<dynamic>(path);
    } catch (e, s) {
      rethrowAsFailure(e, s);
    }
  }

  /// Authenticated file download (report card PDF, report files). These need
  /// the bearer header, so a plain `url_launcher` link cannot fetch them.
  Future<void> download(
    String path,
    String savePath, {
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      await _dio.download(path, savePath, onReceiveProgress: onProgress);
    } catch (e, s) {
      rethrowAsFailure(e, s);
    }
  }

  Future<Json> upload(String path, FormData data) async {
    try {
      final response = await _dio.post<dynamic>(path, data: data);
      return _asObject(response.data);
    } catch (e, s) {
      rethrowAsFailure(e, s);
    }
  }

  /// Dio serializes a `null` query value as an empty string, which FastAPI
  /// then rejects with a 422. Dropping nulls keeps optional filters optional.
  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    final cleaned = <String, dynamic>{};
    query.forEach((key, value) {
      if (value != null) cleaned[key] = value;
    });
    return cleaned.isEmpty ? null : cleaned;
  }

  Json _asObject(Object? data) {
    if (data is Map) return data.cast<String, dynamic>();
    return const {};
  }

  /// Most list endpoints return a bare array, but a couple wrap the rows in
  /// `{"items": [...]}`; accept both rather than crashing on the second shape.
  Object? _asListPayload(Object? data) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in const ['items', 'data', 'results']) {
        if (data[key] is List) return data[key];
      }
    }
    return const [];
  }
}
