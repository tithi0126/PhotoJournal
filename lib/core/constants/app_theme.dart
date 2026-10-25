import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        surface: AppColors.lightSurface,
        primary: AppColors.lightAccent,
        onSurface: AppColors.lightTextPrimary,
        outline: AppColors.lightHairline,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightHairline,
        thickness: 1,
        space: 1,
      ),
      textTheme: TextTheme(
        headlineMedium: AppTypography.serifTitle(color: AppColors.lightTextPrimary),
        titleLarge: AppTypography.serifTitle(fontSize: 20, color: AppColors.lightTextPrimary),
        bodyLarge: AppTypography.body(fontSize: 16, color: AppColors.lightTextPrimary),
        bodyMedium: AppTypography.body(fontSize: 14, color: AppColors.lightTextPrimary),
        bodySmall: AppTypography.body(fontSize: 12, color: AppColors.lightTextSecondary),
        labelSmall: AppTypography.mono(fontSize: 11, color: AppColors.lightTextSecondary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.darkSurface,
        primary: AppColors.darkAccent,
        onSurface: AppColors.darkTextPrimary,
        outline: AppColors.darkHairline,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkHairline,
        thickness: 1,
        space: 1,
      ),
      textTheme: TextTheme(
        headlineMedium: AppTypography.serifTitle(color: AppColors.darkTextPrimary),
        titleLarge: AppTypography.serifTitle(fontSize: 20, color: AppColors.darkTextPrimary),
        bodyLarge: AppTypography.body(fontSize: 16, color: AppColors.darkTextPrimary),
        bodyMedium: AppTypography.body(fontSize: 14, color: AppColors.darkTextPrimary),
        bodySmall: AppTypography.body(fontSize: 12, color: AppColors.darkTextSecondary),
        labelSmall: AppTypography.mono(fontSize: 11, color: AppColors.darkTextSecondary),
      ),
    );
  }
}
