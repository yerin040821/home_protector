// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Backgrounds — 밝고 시원한 톤 ──
  static const Color bgPrimary = Color(0xFFFFFFFF);
  static const Color bgSurface = Color(0xFFF5F7FB); // 쿨한 라이트 그레이
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgCardDark = Color(0xFFEEF1F8);

  // ── Brand accent — 모던 인디고-블루 (주요 브랜드 모먼트) ──
  static const Color accent = Color(0xFF4C6FFF);
  static const Color accentDark = Color(0xFF3A57E8);
  static const Color accentLight = Color(0xFFEEF2FF);
  static const Color accent2 = Color(0xFF31D0E6); // 그라데이션 페어(시안)

  // ── Danger (빨강) — 부드러운 모던 레드 ──
  static const Color red = Color(0xFFFF4D63);
  static const Color redDark = Color(0xFFE23150);
  static const Color redLight = Color(0xFFFFE7EB);

  // ── Caution / secondary highlight (앰버) ──
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFFD97706);
  static const Color amberLight = Color(0xFFFFF4E0);

  static const Color kakao = Color(0xFFFEE500);

  // ── Text ──
  static const Color textPrimary = Color(0xFF111726);
  static const Color textSecondary = Color(0xFF5A6575);
  static const Color textMuted = Color(0xFF98A2B3);

  // ── Status ──
  static const Color danger = Color(0xFFFF4D63);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF4C6FFF);
  static const Color success = Color(0xFF18C29C);

  // ── Border — 아주 옅게 ──
  static const Color border = Color(0xFFEAEDF4);
  static const Color borderLight = Color(0xFFF2F4FA);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        secondary: AppColors.amber,
        surface: AppColors.bgSurface,
        error: AppColors.danger,
      ),
      textTheme: GoogleFonts.notoSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: AppColors.textPrimary),
          displayMedium: TextStyle(color: AppColors.textPrimary),
          displaySmall: TextStyle(color: AppColors.textPrimary),
          headlineLarge: TextStyle(color: AppColors.textPrimary),
          headlineMedium: TextStyle(color: AppColors.textPrimary),
          headlineSmall: TextStyle(color: AppColors.textPrimary),
          titleLarge: TextStyle(color: AppColors.textPrimary),
          titleMedium: TextStyle(color: AppColors.textPrimary),
          titleSmall: TextStyle(color: AppColors.textPrimary),
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textSecondary),
          bodySmall: TextStyle(color: AppColors.textMuted),
          labelLarge: TextStyle(color: AppColors.textPrimary),
          labelMedium: TextStyle(color: AppColors.textSecondary),
          labelSmall: TextStyle(color: AppColors.textMuted),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgSurface,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

