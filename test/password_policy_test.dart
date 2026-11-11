// UT-APP-01 · APP-04 · Política de contraseña (PR-04).
//
// Contrato tomado de la planeación de correcciones (APP-04, «Diseño»):
//   lib/core/domain/password_policy.dart con `PasswordPolicy.isValid(pwd)`.
// Los seis valores son los mismos de la API y la web.
//
// Resultado esperado antes de la corrección: FALLA (no compila porque
// `PasswordPolicy` no existe). Después de APP-04: pasa.
import 'package:eyes_school/core/domain/password_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordPolicy (UT-APP-01)', () {
    test('Colegio#2026 cumple las cinco reglas', () {
      expect(PasswordPolicy.isValid('Colegio#2026'), isTrue);
    });

    // Cada valor incumple exactamente una regla.
    const invalidas = {
      'Ab1#': 'menos de 8 caracteres',
      'colegio#2026': 'sin mayúscula',
      'COLEGIO#2026': 'sin minúscula',
      'Colegio#ocho': 'sin número',
      'Colegio2026': 'sin carácter especial',
    };

    invalidas.forEach((valor, regla) {
      test('«$valor» se rechaza ($regla)', () {
        expect(PasswordPolicy.isValid(valor), isFalse);
      });
    });
  });
}
