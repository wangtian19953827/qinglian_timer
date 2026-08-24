import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color bgTop = Color(0xFFF1FBF6);
  static const Color bgMid = Color(0xFFE3F8EF);
  static const Color bgBottom = Color(0xFFECF6FB);
  static const Color ink = Color(0xFF24473D);
  static const Color inkSoft = Color(0x9E24473D);
  static const Color accent = Color(0xFF16A07E);
  static const Color accent2 = Color(0xFF4B93B8);
  static const Color gradientStart = Color(0xFF2AB58D);
  static const Color gradientEnd = Color(0xFF4B9FC4);
  static const Color surface = Color(0x8FFFFFFF);
  static const Color surfaceStrong = Color(0xBFFFFFFF);
  static const Color line = Color(0x264F705F);
  static const Color shadow = Color(0x5C1A8E6F);
  static const Color lace = Color(0x52FFFFFF);
  static const Color warm = Color(0xFFF2B84B);
  static const Color accentSoft = Color(0x3D16A07E);
}

ThemeData buildAppTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: base.copyWith(
      primary: AppColors.accent,
      secondary: AppColors.accent2,
      surface: Colors.white,
      onSurface: AppColors.ink,
    ),
    scaffoldBackgroundColor: AppColors.bgTop,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.ink,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}