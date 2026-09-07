import 'package:flutter/material.dart';

class AppColors {
  static const Color dark = Color(0xFF1A1A2E);
  static const Color purple = Color(0xFF7F77DD);
  static const Color purpleDark = Color(0xFF534AB7);
  static const Color purpleLight = Color(0xFFEEEDFE);
  static const Color green = Color(0xFF0F6E56);
  static const Color greenLight = Color(0xFFE1F5EE);
  static const Color greenBright = Color(0xFF1D9E75);
  static const Color greenDark = Color(0xFF0B5C47);
  static const Color amber = Color(0xFF854F0B);
  static const Color amberLight = Color(0xFFFAEEDA);
  static const Color amberBright = Color(0xFFBA7517);
  static const Color amberDark = Color(0xFF7A3300);
  static const Color amberGold = Color(0xFFFAC775);
  static const Color amberText = Color(0xFF633806);
  static const Color red = Color(0xFFE24B4A);
  static const Color redDark = Color(0xFFA32D2D);
  static const Color redLight = Color(0xFFFCEBEB);
  static const Color bg = Color(0xFFF4F4F8);
  static const Color white = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEBEBF0);
  static const Color borderMid = Color(0xFFE0E0E8);
  static const Color textMuted = Color(0xFF999999);
  static const Color textLight = Color(0xFFABABC0);
  static const Color navActive = Color(0xFF534AB7);
  static const Color navInactive = Color(0xFFABABC0);
}

/// Shared type scale. Screens should use these instead of hand-coding
/// fontSize/fontWeight per Text widget, so hierarchy stays consistent.
class AppText {
  /// Big numeric display (queue numbers).
  static const TextStyle display = TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w700,
    height: 1,
    color: AppColors.dark,
  );

  /// Screen headline.
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.dark,
  );

  /// Card/section heading.
  static const TextStyle heading = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.dark,
  );

  /// Default reading text.
  static const TextStyle body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.dark,
  );

  /// Secondary/supporting text.
  static const TextStyle bodyMuted = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textMuted,
  );

  /// Buttons and other interactive labels.
  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.dark,
  );

  /// Fine print, timestamps, helper text.
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textMuted,
  );

  /// Uppercase micro-label above a group of content.
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: AppColors.textMuted,
  );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.purple),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.dark,
      foregroundColor: AppColors.white,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displaySmall: AppText.display,
      titleLarge: AppText.title,
      titleMedium: AppText.heading,
      bodyMedium: AppText.body,
      bodySmall: AppText.bodyMuted,
      labelLarge: AppText.label,
      labelSmall: AppText.caption,
    ),
    useMaterial3: true,
  );
}
