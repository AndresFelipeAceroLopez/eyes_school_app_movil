import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static final TextStyle _base = GoogleFonts.plusJakartaSans(color: AppColors.textPrimary);

  static TextStyle get h1 =>
      _base.copyWith(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2);
  static TextStyle get h2 =>
      _base.copyWith(fontSize: 20, fontWeight: FontWeight.w800, height: 1.2);
  static TextStyle get h3 =>
      _base.copyWith(fontSize: 17, fontWeight: FontWeight.w700, height: 1.3);

  static TextStyle get statValue =>
      _base.copyWith(fontSize: 24, fontWeight: FontWeight.w800);
  static TextStyle get statLabel => _base.copyWith(
      fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textOnDarkMuted);

  static TextStyle get body =>
      _base.copyWith(fontSize: 14.5, fontWeight: FontWeight.w500, height: 1.4);
  static TextStyle get bodyMuted => body.copyWith(color: AppColors.textSecondary);

  static TextStyle get caption =>
      _base.copyWith(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textSecondary);

  static TextStyle get button =>
      _base.copyWith(fontSize: 15.5, fontWeight: FontWeight.w700, color: Colors.white);

  static TextStyle get link =>
      _base.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.indigo);
}
