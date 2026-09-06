/// `TipoNovedadOut.nivel_gravedad` and `NovedadOut.estado`, as domain terms.
library;

enum NovedadSeverity {
  low('Bajo', 'Baja'),
  medium('Medio', 'Media'),
  high('Alto', 'Alta'),
  critical('Crítico', 'Crítica');

  const NovedadSeverity(this.wire, this.label);

  /// What the API stores.
  final String wire;

  /// What a person reads ("gravedad alta").
  final String label;

  static NovedadSeverity parse(String? value) {
    final normalized = (value ?? '').toLowerCase().trim();
    for (final severity in values) {
      if (severity.wire.toLowerCase() == normalized || severity.name == normalized) {
        return severity;
      }
    }
    if (normalized.startsWith('crit')) return NovedadSeverity.critical;
    return NovedadSeverity.low;
  }
}

/// The API accepts only these two states on `NovedadUpdate`.
enum NovedadStatus {
  pending('Pendiente'),
  done('Completado');

  const NovedadStatus(this.label);

  final String label;

  static NovedadStatus parse(String? value) {
    final normalized = (value ?? '').toLowerCase().trim();
    return normalized.startsWith('comp') ? NovedadStatus.done : NovedadStatus.pending;
  }
}

/// The institutional grading scale, 0.0 – 5.0.
abstract final class GradeScale {
  static const double max = 5.0;
  static const double passing = 3.0;

  static bool isValid(double score) => score >= 0 && score <= max;

  /// 0..1, for progress bars.
  static double progressOf(double score) => (score / max).clamp(0, 1);

  static String qualitativeOf(double score) {
    if (score >= 4.6) return 'Excelente';
    if (score >= 4.0) return 'Sobresaliente';
    if (score >= passing) return 'Aceptable';
    return 'Bajo';
  }
}

/// The academic calendar. There is no `/periodos` endpoint, so the four
/// periods are an institutional constant.
abstract final class AcademicPeriods {
  static const List<int> all = [1, 2, 3, 4];

  static String labelOf(int period) => 'Periodo $period';

  static bool isValid(int period) => all.contains(period);
}
