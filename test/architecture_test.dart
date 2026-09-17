import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture rules, enforced instead of merely documented.
///
/// A layered design decays one convenient import at a time. These tests fail
/// the build the first time someone reaches across a boundary, which is the
/// only way the boundary survives contact with a deadline.
void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  List<File> under(String folder) => dartFiles
      .where((f) => f.path.replaceAll(r'\', '/').contains('lib/$folder/'))
      .toList();

  List<String> importsOf(File file) => file
      .readAsLinesSync()
      .where((line) => line.startsWith('import '))
      .toList();

  String relative(File file) => file.path.replaceAll(r'\', '/');

  group('El dominio es puro', () {
    test('no depende de Flutter, de Dio ni de ningún paquete externo', () {
      final offenders = <String>[];
      for (final file in under('domain')) {
        for (final line in importsOf(file)) {
          // A domain that imports `package:flutter` cannot be unit-tested
          // without a widget binding, and cannot be reused off Flutter at all.
          if (line.contains('package:')) {
            offenders.add('${relative(file)} → $line');
          }
        }
      }
      expect(offenders, isEmpty,
          reason: 'El dominio debe ser Dart puro:\n${offenders.join('\n')}');
    });

    test('no conoce las capas de datos ni de presentación', () {
      final offenders = <String>[];
      for (final file in under('domain')) {
        for (final line in importsOf(file)) {
          if (line.contains('/data/') ||
              line.contains('/features/') ||
              line.contains('/providers/') ||
              line.contains('/core/')) {
            offenders.add('${relative(file)} → $line');
          }
        }
      }
      expect(offenders, isEmpty,
          reason: 'La dependencia apunta hacia adentro:\n${offenders.join('\n')}');
    });
  });

  group('La presentación habla el idioma del dominio', () {
    test('ninguna pantalla importa un DTO, un API o Dio', () {
      final offenders = <String>[];
      for (final file in [...under('features'), ...under('core/widgets')]) {
        if (relative(file).contains('/data/')) continue;
        for (final line in importsOf(file)) {
          if (line.contains('data/dto/') ||
              line.contains('data/api/') ||
              line.contains('package:dio')) {
            offenders.add('${relative(file)} → $line');
          }
        }
      }
      expect(offenders, isEmpty,
          reason: 'Las pantallas solo ven entidades:\n${offenders.join('\n')}');
    });

    test('ninguna pantalla instancia un repositorio concreto', () {
      final offenders = <String>[];
      for (final file in [...under('features'), ...under('core/widgets')]) {
        for (final line in importsOf(file)) {
          if (line.contains('data/repositories/')) {
            offenders.add('${relative(file)} → $line');
          }
        }
      }
      expect(offenders, isEmpty,
          reason: 'Se depende del contrato, no de la implementación:\n'
              '${offenders.join('\n')}');
    });
  });

  test('solo la raíz de composición conoce las implementaciones', () {
    final offenders = <String>[];
    for (final file in dartFiles) {
      final path = relative(file);
      if (path.endsWith('providers/repository_providers.dart')) continue;
      if (path.contains('lib/data/')) continue;
      for (final line in importsOf(file)) {
        if (line.contains('_repository_impl.dart')) {
          offenders.add('$path → $line');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'Las implementaciones se cablean en un solo lugar:\n'
            '${offenders.join('\n')}');
  });
}
