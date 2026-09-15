import 'package:eyes_school/core/utils/json_x.dart';
import 'package:eyes_school/features/dashboard/domain/dashboard.dart';

/// `ReporteOut` → [Report]. Read-only on mobile.
abstract final class ReportMapper {
  static Report fromJson(Json json) {
    final path = asStringOrNull(json['ruta_archivo']);
    return Report(
      id: asInt(json['id_reporte']),
      type: asString(json['tipo_reporte'], fallback: 'General'),
      status: asString(json['estado'], fallback: 'Pendiente'),
      title: asStringOrNull(json['titulo']) ?? asStringOrNull(json['nombre_reporte']),
      description: asStringOrNull(json['descripcion']),
      generatedAt: asDate(json['fecha_generacion']) ?? asDate(json['fecha_creacion']),
      hasFile: path != null && path.isNotEmpty,
    );
  }
}
