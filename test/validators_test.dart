import 'package:eyes_school/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

/// The login form is the front door: a validator that is stricter than reality
/// locks real users out before a single request is made.
void main() {
  group('Validators.email', () {
    test('acepta los dominios institucionales de varios niveles', () {
      // El caso que bloqueaba el ingreso: `.edu.co` tiene dos puntos.
      expect(Validators.email('admin@eyesschool.edu.co'), isNull);
      expect(Validators.email('carlos.jimenez@eyes.edu.co'), isNull);
      expect(Validators.email('rector@colegio.gov.co'), isNull);
      expect(Validators.email('info@mi.colegio.com.co'), isNull);
    });

    test('acepta los dominios de un solo nivel', () {
      expect(Validators.email('tu@correo.com'), isNull);
      expect(Validators.email('ana+notas@gmail.com'), isNull);
      expect(Validators.email('juan_perez@outlook.es'), isNull);
    });

    test('ignora espacios alrededor', () {
      expect(Validators.email('  admin@eyesschool.edu.co  '), isNull);
    });

    test('sigue rechazando lo que no es un correo', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('admin'), isNotNull);
      expect(Validators.email('admin@'), isNotNull);
      expect(Validators.email('admin@colegio'), isNotNull);
      expect(Validators.email('@eyesschool.edu.co'), isNotNull);
      expect(Validators.email('admin eyesschool.edu.co'), isNotNull);
    });
  });

  group('Validators.gradeScore', () {
    test('acepta la escala institucional 0.0–5.0', () {
      expect(Validators.gradeScore('0'), isNull);
      expect(Validators.gradeScore('3.5'), isNull);
      expect(Validators.gradeScore('5.0'), isNull);
      // El teclado del teléfono escribe coma en configuración regional es-CO.
      expect(Validators.gradeScore('4,2'), isNull);
      expect(Validators.parseScore('4,2'), 4.2);
    });

    test('rechaza lo que está fuera de la escala', () {
      expect(Validators.gradeScore('5.1'), isNotNull);
      expect(Validators.gradeScore('9'), isNotNull);
      expect(Validators.gradeScore('-1'), isNotNull);
      expect(Validators.gradeScore('abc'), isNotNull);
      expect(Validators.gradeScore(''), isNotNull);
    });
  });

  group('Validators.newPassword', () {
    test('exige una longitud mínima al fijarla', () {
      expect(Validators.newPassword('Admin2026*'), isNull);
      expect(Validators.newPassword('corta'), isNotNull);
      expect(Validators.newPassword(''), isNotNull);
    });

    test('al ingresar solo se exige que no esté vacía', () {
      // El login no impone reglas de fortaleza: la contraseña ya existe.
      expect(Validators.password('Admin2026*'), isNull);
      expect(Validators.password('x'), isNull);
      expect(Validators.password(''), isNotNull);
    });
  });
}
