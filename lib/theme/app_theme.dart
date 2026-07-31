import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFFF8FAFC);
  static const Color foreground = Color(0xFF0F172A);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF0F172A);
  static const Color popover = Color(0xFFFFFFFF);
  static const Color popoverForeground = Color(0xFF0F172A);
  static const Color primary = Color(0xFF0EA5E9);
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFF1F5F9);
  static const Color secondaryForeground = Color(0xFF0F172A);
  static const Color muted = Color(0xFFF1F5F9);
  static const Color mutedForeground = Color(0xFF64748B);
  static const Color accent = Color(0xFFF1F5F9);
  static const Color accentForeground = Color(0xFF0F172A);
  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF16A34A);
  static const Color successForeground = Color(0xFFF0FDF4);
  static const Color warning = Color(0xFFF97316);
  static const Color warningForeground = Color(0xFFFFFAF0);
  static const Color border = Color(0xFFE2E8F0);
  static const Color input = Color(0xFFE2E8F0);
  static const Color ring = Color(0xFF0EA5E9);
  static const Color sidebar = Color(0xFFF1F5F9);
  static const Color sidebarForeground = Color(0xFF0F172A);
  static const Color sidebarPrimary = Color(0xFF3B82F6);
  static const Color sidebarPrimaryForeground = Color(0xFFF8FAFC);
  static const Color sidebarAccent = Color(0xFFE0F2FE);
  static const Color sidebarAccentForeground = Color(0xFF3B82F6);
  static const Color sidebarBorder = Color(0xFFCBD5E1);

  static const Color chart1 = Color(0xFF0EA5E9);
  static const Color chart2 = Color(0xFF3B82F6);
  static const Color chart3 = Color(0xFF8B5CF6);
  static const Color chart4 = Color(0xFFA855F7);
  static const Color chart5 = Color(0xFFEC4899);

  static const Color sky50 = Color(0xFFF0F9FF);
  static const Color sky100 = Color(0xFFE0F2FE);
  static const Color sky200 = Color(0xFFBAE6FD);
  static const Color sky500 = Color(0xFF0EA5E9);
  static const Color sky600 = Color(0xFF0284C7);

  static const Color emerald50 = Color(0xFFF0FDF4);
  static const Color emerald100 = Color(0xFFDCFCE7);
  static const Color emerald200 = Color(0xFFBBF7D0);
  static const Color emerald500 = Color(0xFF22C55E);
  static const Color emerald600 = Color(0xFF16A34A);
  static const Color emerald700 = Color(0xFF15803D);

  static const Color orange50 = Color(0xFFFFFAF0);
  static const Color orange100 = Color(0xFFFEF3C7);
  static const Color orange200 = Color(0xFFFDE68A);
  static const Color orange500 = Color(0xFFF97316);
  static const Color orange600 = Color(0xFFEA580C);
  static const Color orange700 = Color(0xFFC2410C);

  static const Color purple50 = Color(0xFFFAF5FF);
  static const Color purple100 = Color(0xFFF3E8FF);
  static const Color purple200 = Color(0xFFE9D5FF);
  static const Color purple500 = Color(0xFFA855F7);
  static const Color purple600 = Color(0xFF9333EA);
  static const Color purple700 = Color(0xFF7E22CE);

  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);

  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red200 = Color(0xFFFECACA);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red700 = Color(0xFFB91C1C);

  static const Color amber50 = Color(0xFFFFFBF0);
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color amber900 = Color(0xFF78350F);
}

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.primaryForeground,
      secondary: AppColors.secondary,
      onSecondary: AppColors.secondaryForeground,
      surface: AppColors.background,
      onSurface: AppColors.foreground,
      error: AppColors.destructive,
      onError: AppColors.destructiveForeground,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      cardColor: AppColors.card,
      dividerColor: AppColors.border,
      shadowColor: Colors.black.withValues(alpha: 0.02),
      fontFamily: GoogleFonts.notoSansSc().fontFamily,
      textTheme: GoogleFonts.notoSansScTextTheme(
        TextTheme(
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.foreground),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.foreground),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground),
          bodyLarge: TextStyle(fontSize: 15, color: AppColors.foreground),
          bodyMedium: TextStyle(fontSize: 14, color: AppColors.foreground),
          bodySmall: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle: const TextStyle(color: AppColors.mutedForeground, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foreground,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.foreground,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.primaryForeground),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: AppColors.border),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.secondary,
        selectedColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.foreground,
        contentTextStyle: const TextStyle(color: AppColors.card, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
