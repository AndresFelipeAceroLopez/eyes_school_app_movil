import '../../domain/value_objects/severity.dart';

abstract final class Validators {
  /// Accepts multi-label domains: the institution uses `@eyesschool.edu.co`,
  /// and a pattern that allows a single dot after the `@` rejects every
  /// `.edu.co` / `.com.co` address there is.
  static final _emailRegex =
      RegExp(r'^[\w.+-]+@[\w-]+(?:\.[\w-]+)*\.[a-zA-Z]{2,}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo electrónico.';
    if (!_emailRegex.hasMatch(v)) return 'Ingresa un correo válido.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña.';
    return null;
  }

  /// Used on sign-up and password change, where the value is being set rather
  /// than merely typed back.
  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa una contraseña.';
    if (value.length < 8) return 'Usa al menos 8 caracteres.';
    return null;
  }

  static String? required(String? value, String what) {
    if (value == null || value.trim().isEmpty) return 'Ingresa $what.';
    return null;
  }

  /// The institutional scale is 0.0 – 5.0, the same rule the web panel applies.
  static String? gradeScore(String? value) {
    final text = value?.trim().replaceAll(',', '.') ?? '';
    if (text.isEmpty) return 'Ingresa la nota.';
    final score = double.tryParse(text);
    if (score == null) return 'Ingresa un número válido.';
    if (!GradeScale.isValid(score)) {
      return 'La nota debe estar entre 0.0 y ${GradeScale.max.toStringAsFixed(1)}.';
    }
    return null;
  }

  static double? parseScore(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', '.'));
}
