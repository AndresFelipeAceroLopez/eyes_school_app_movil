// Resume coverage/lcov.info por capa (domain, data, presentacion, core) y
// opcionalmente falla si la logica de negocio queda por debajo del umbral.
//
//   flutter test --coverage
//   dart run tool/coverage_report.dart [--min-logic=N]
//
//   --min-logic=N  sale con codigo 1 si la cobertura conjunta de las capas
//                  `domain` y `data` es menor a N % (umbral del MC-01).
//
// Se mide la logica por separado porque las pantallas se validan con pruebas
// de sistema y de aceptacion, no con pruebas unitarias; mezclarlas en un solo
// porcentaje esconde si lo que de verdad importa esta probado.

import 'dart:io';

const _lcovPath = 'coverage/lcov.info';

String _layerOf(String path) {
  final p = path.replaceAll(r'\', '/');
  if (p.contains('/domain/')) return 'domain';
  if (p.contains('/data/')) return 'data';
  if (p.contains('/presentation/') ||
      p.contains('/widgets/') ||
      p.contains('/theme/') ||
      p.endsWith('_screen.dart')) {
    return 'presentacion';
  }
  return 'core';
}

void main(List<String> args) {
  double? minLogic;
  for (final arg in args) {
    if (arg.startsWith('--min-logic=')) {
      minLogic = double.parse(arg.substring('--min-logic='.length));
    }
  }

  final file = File(_lcovPath);
  if (!file.existsSync()) {
    stderr.writeln(
      'No existe $_lcovPath. Ejecute primero: flutter test --coverage',
    );
    exit(2);
  }

  final found = <String, int>{};
  final hit = <String, int>{};
  var layer = 'core';
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      layer = _layerOf(line.substring(3));
    } else if (line.startsWith('LF:')) {
      found[layer] = (found[layer] ?? 0) + int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hit[layer] = (hit[layer] ?? 0) + int.parse(line.substring(3));
    }
  }

  double pct(int h, int f) => f == 0 ? 100 : 100 * h / f;
  String row(String name, int h, int f) =>
      '${name.padRight(14)}${'$h/$f'.padLeft(12)}${pct(h, f).toStringAsFixed(1).padLeft(8)} %';

  stdout.writeln(
    '${'Capa'.padRight(14)}${'Lineas'.padLeft(12)}${'Cobertura'.padLeft(10)}',
  );
  for (final name in ['domain', 'data', 'core', 'presentacion']) {
    stdout.writeln(row(name, hit[name] ?? 0, found[name] ?? 0));
  }

  final logicHit = (hit['domain'] ?? 0) + (hit['data'] ?? 0);
  final logicFound = (found['domain'] ?? 0) + (found['data'] ?? 0);
  final totalHit = hit.values.fold(0, (a, b) => a + b);
  final totalFound = found.values.fold(0, (a, b) => a + b);
  stdout.writeln(row('logica', logicHit, logicFound));
  stdout.writeln(row('total', totalHit, totalFound));

  if (minLogic != null) {
    final logic = pct(logicHit, logicFound);
    if (logic < minLogic) {
      stderr.writeln(
        'Cobertura de logica ${logic.toStringAsFixed(1)} % < umbral $minLogic %',
      );
      exit(1);
    }
    stdout.writeln('Umbral de logica ($minLogic %) cumplido.');
  }
}
