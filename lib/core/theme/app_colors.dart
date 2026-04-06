import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFF9B8FEF);
  static const Color primaryDark = Color(0xFF4A3DB5);

  static const Color darkBg = Color(0xFF0D0D0D);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);
  static const Color darkCardLight = Color(0xFF1E2A4A);

  static const Color lightBg = Color(0xFFF8F9FE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0F0F8);

  static const Color accent = Color(0xFF00D2FF);
  static const Color accentAlt = Color(0xFFFF6B6B);

  static const Color textPrimary = Color(0xFFE8E8E8);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textDarkSecondary = Color(0xFF6B7280);

  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFAB00);
  static const Color live = Color(0xFFFF0000);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [darkBg, darkSurface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
