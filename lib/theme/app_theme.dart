import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static const _shape16 = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );
  static const _shape12 = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );

  // Tranzitii animate globale — standard Google Material 3
  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.electricBlue,
    scaffoldBackgroundColor: AppColors.background,
    pageTransitionsTheme: _pageTransitions,
    colorScheme: const ColorScheme.light(
      primary: AppColors.electricBlue,
      secondary: AppColors.secondary,
      error: AppColors.error,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceVariant,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.electricBlue,
        shape: _shape16,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.electricBlue,
        side: const BorderSide(color: AppColors.electricBlue),
        shape: _shape16,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.electricBlue, width: 2),
      ),
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      shape: _shape12,
      margin: EdgeInsets.symmetric(vertical: 4),
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: Colors.transparent,
      horizontalTitleGap: 12,
      minVerticalPadding: 4,
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: AppColors.electricBlue,
      textTheme: ButtonTextTheme.primary,
      shape: _shape16,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.indigoDeep,
    scaffoldBackgroundColor: AppColors.darkBackground,
    pageTransitionsTheme: _pageTransitions,
    colorScheme: ColorScheme.dark(
      primary: AppColors.indigoDeep,
      secondary: AppColors.secondary,
      surface: AppColors.darkSurface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white.withAlpha(222),
      onError: Colors.white,
      surfaceContainerHighest: AppColors.darkSurfaceElevated,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.indigoDeep,
        shape: _shape16,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        side: const BorderSide(color: AppColors.indigoDeep),
        shape: _shape16,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.indigoDeep, width: 2),
      ),
      hintStyle: TextStyle(color: Colors.white.withAlpha(100), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: AppColors.darkSurface,
      shape: _shape12,
      margin: EdgeInsets.symmetric(vertical: 4),
    ),
    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      horizontalTitleGap: 12,
      minVerticalPadding: 4,
      titleTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 13,
        color: Colors.white.withAlpha(180),
      ),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: AppColors.indigoDeep,
      textTheme: ButtonTextTheme.primary,
      shape: _shape16,
    ),
  );

  // High-contrast variants
  static final ThemeData highContrastLight = lightTheme.copyWith(
    colorScheme: lightTheme.colorScheme.copyWith(
      onSurface: Colors.black,
      surface: Colors.white,
    ),
    textTheme: lightTheme.textTheme.apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ),
    dividerColor: Colors.black,
    focusColor: Colors.black,
  );

  static final ThemeData highContrastDark = darkTheme.copyWith(
    colorScheme: darkTheme.colorScheme.copyWith(
      onSurface: Colors.white,
      surface: const Color(0xFF000000),
    ),
    textTheme: darkTheme.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    dividerColor: Colors.white,
    focusColor: Colors.white,
  );
}