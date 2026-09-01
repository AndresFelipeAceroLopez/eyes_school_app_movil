import 'package:flutter/material.dart';

/// Centralized color tokens for EyeSchool, derived from the product mockups.
abstract final class AppColors {
  // Header gradient (dark navy -> indigo/purple)
  static const headerGradient = [
    Color(0xFF0A0E3D),
    Color(0xFF1E1256),
    Color(0xFF3B1E7A),
  ];

  // Primary action gradient (buttons, FAB, center nav button)
  static const primaryGradient = [
    Color(0xFF4B2AAE),
    Color(0xFF7C4FE0),
  ];

  static const background = Color(0xFFF4F5F9);
  static const surface = Colors.white;

  static const teal = Color(0xFF2DD6C4);
  static const tealDark = Color(0xFF0E9E8F);
  static const indigo = Color(0xFF5B34D6);
  static const violet = Color(0xFF7C4FE0);

  static const pink = Color(0xFFFF5C7A);
  static const orange = Color(0xFFFFA94D);
  static const blue = Color(0xFF5B7CFA);
  static const green = Color(0xFF22C55E);

  static const textPrimary = Color(0xFF1A1B33);
  static const textSecondary = Color(0xFF7C7F93);
  static const textOnDark = Colors.white;
  static const textOnDarkMuted = Color(0xFFB7B9D6);

  static const cardShadow = Color(0x14140A33);
  static const divider = Color(0xFFECEDF4);

  // Role badge colors
  static const roleTeacher = Color(0xFFB794F6);
  static const roleTeacherBg = Color(0xFFF1E9FE);
  static const roleStudent = Color(0xFF5B7CFA);
  static const roleStudentBg = Color(0xFFE9EDFE);
  static const roleAdmin = Color(0xFF0E9E8F);
  static const roleAdminBg = Color(0xFFDDF8F3);
  static const roleParent = Color(0xFFE08A3C);
  static const roleParentBg = Color(0xFFFCEEDD);

  static const statusActiveBg = Color(0xFFDDF8F3);
  static const statusActiveFg = Color(0xFF0E9E8F);
  static const statusInactiveBg = Color(0xFFF1F1F6);
  static const statusInactiveFg = Color(0xFF8A8CA3);
}
