// UT-APP-04 · APP-06 · Correo en minúsculas (PR-04).
//
// Contrato de la planeación (APP-06): función pura `normalizeEmail(String)`
// en lib/core/utils/ que hace trim().toLowerCase().
// La planeación no nombra el archivo: QA asume `validators.dart`, junto a
// `Validators.email`. Si el desarrollador la pone en otro archivo de
// lib/core/utils/, solo cambia el import.
//
// Va en un archivo propio (y no en validators_test.dart, como dice la
// planeación) porque mientras la función no exista el archivo no compila y
// arrastraría a las 8 pruebas existentes de validadores.
//
// Antes de la corrección: FALLA (no compila). Después de APP-06: pasa.
import 'package:eyes_school/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeEmail (UT-APP-04)', () {
    test('« Ana@X.com » → «ana@x.com»', () {
      expect(normalizeEmail(' Ana@X.com '), 'ana@x.com');
    });

    test('un correo ya normalizado no cambia', () {
      expect(
        normalizeEmail('carlos.jimenez@eyes.edu.co'),
        'carlos.jimenez@eyes.edu.co',
      );
    });

    test(
      'el correo del docente de DS-01 escrito con mayúsculas y espacios',
      () {
        expect(
          normalizeEmail('  Carlos.Jimenez@Eyes.edu.co  '),
          'carlos.jimenez@eyes.edu.co',
        );
      },
    );
  });
}
