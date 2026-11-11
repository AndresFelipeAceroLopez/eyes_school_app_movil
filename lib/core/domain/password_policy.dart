/// Institutional password rule (APP-04), the same five conditions the web
/// panel and the API (BE-09) enforce. Pure Dart: it lives in the domain so the
/// three forms that set a password (register, reset, profile) share it.
enum PasswordRule {
  length('Usa al menos 8 caracteres.'),
  upper('Incluye al menos una letra mayúscula.'),
  lower('Incluye al menos una letra minúscula.'),
  number('Incluye al menos un número.'),
  special('Incluye al menos un carácter especial (por ejemplo # o *).');

  const PasswordRule(this.message);

  /// What the form shows when this rule is not met.
  final String message;
}

abstract final class PasswordPolicy {
  static const minLength = 8;

  static final _upper = RegExp(r'[A-ZÁÉÍÓÚÑÜ]');
  static final _lower = RegExp(r'[a-záéíóúñü]');
  static final _number = RegExp(r'[0-9]');
  static final _special = RegExp(r'[^A-Za-z0-9ÁÉÍÓÚÑÜáéíóúñü\s]');

  /// Every rule with whether [password] meets it, in the order the form
  /// reports them.
  static Map<PasswordRule, bool> check(String password) => {
        PasswordRule.length: password.length >= minLength,
        PasswordRule.upper: _upper.hasMatch(password),
        PasswordRule.lower: _lower.hasMatch(password),
        PasswordRule.number: _number.hasMatch(password),
        PasswordRule.special: _special.hasMatch(password),
      };

  /// The first rule [password] breaks, or `null` when it meets all five.
  static PasswordRule? firstFailure(String password) {
    for (final entry in check(password).entries) {
      if (!entry.value) return entry.key;
    }
    return null;
  }

  static bool isValid(String password) => firstFailure(password) == null;
}
