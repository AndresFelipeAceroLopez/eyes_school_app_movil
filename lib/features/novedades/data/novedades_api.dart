import 'package:eyes_school/core/network/api_config.dart';
import 'package:eyes_school/core/utils/json_x.dart';
import 'package:eyes_school/features/novedades/domain/novedad.dart';
import 'package:eyes_school/features/novedades/domain/severity.dart';
import 'package:eyes_school/features/novedades/data/novedad_dto.dart';
import 'package:eyes_school/core/network/api_client.dart';

/// `/novedades` y `/tipos-novedad`.
class NovedadesApi {
  const NovedadesApi(this._client);

  final ApiClient _client;

  /// Catalog with the severity each type carries. Cached like courses.
  Future<List<NovedadType>> types() =>
      _client.getList('/tipos-novedad', NovedadTypeMapper.fromJson);

  Future<List<Json>> rawList({
    int? studentId,
    int? typeId,
    NovedadStatus? status,
    int skip = 0,
    int limit = ApiConfig.pageSize,
  }) {
    return _client.getList('/novedades', (json) => json, query: {
      'id_estudiante': studentId,
      'id_tipo': typeId,
      'estado': status?.label,
      'skip': skip,
      'limit': limit,
    });
  }

  Future<void> create(Json payload) => _client.post('/novedades', body: payload);

  Future<void> update(
    int novedadId, {
    String? description,
    String? action,
    NovedadStatus? status,
    DateTime? resolvedOn,
    int? typeId,
  }) {
    return _client.put('/novedades/$novedadId', body: <String, dynamic>{
      'descripcion': ?description,
      'accion_tomada': ?action,
      if (status != null) 'estado': status.label,
      if (resolvedOn != null) 'fecha_resolucion': toApiDate(resolvedOn),
      'id_tipo_novedad': ?typeId,
    });
  }

  Future<void> delete(int novedadId) => _client.delete('/novedades/$novedadId');
}
