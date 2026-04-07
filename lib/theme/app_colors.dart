import 'package:flutter/material.dart';

class AppColors {
  // ── Brand Colors (Electric Blue → Indigo) ──────────────────────────────────
  static const Color electricBlue   = Color(0xFF2563EB); // Electric Blue (primary)
  static const Color indigoDeep     = Color(0xFF4F46E5); // Deep Indigo
  static const Color violetAccent   = Color(0xFF7C3AED); // Violet accent

  // Legacy aliases (backward compat with existing widgets)
  static const Color primary        = electricBlue;
  static const Color primaryLight   = Color(0xFF60A5FA); // Sky Blue
  static const Color primaryDark    = indigoDeep;

  // ── Secondary (Green) ─────────────────────────────────────────────────────
  static const Color secondary      = Color(0xFF059669); // Emerald
  static const Color secondaryLight = Color(0xFF34D399); // Light Emerald
  static const Color secondaryDark  = Color(0xFF047857); // Dark Emerald

  // ── Accent & Status ───────────────────────────────────────────────────────
  static const Color accent  = Color(0xFFF97316); // Orange CTA
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error   = Color(0xFFEF4444); // Red
  static const Color success = Color(0xFF10B981); // Emerald success

  // ── Light Mode Surfaces ───────────────────────────────────────────────────
  static const Color background     = Color(0xFFF8FAFC); // Slate-50
  static const Color surface        = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate-100

  // ── Dark Mode Surfaces ────────────────────────────────────────────────────
  static const Color darkBackground       = Color(0xFF0F0F1A); // Deep dark
  static const Color darkSurface          = Color(0xFF1A1A2E); // Dark surface
  static const Color darkSurfaceElevated  = Color(0xFF252545); // Elevated card

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F172A); // Slate-900
  static const Color textSecondary = Color(0xFF64748B); // Slate-500
  static const Color textDisabled  = Color(0xFFCBD5E1); // Slate-300
  static const Color textOnPrimary = Colors.white;
  static const Color textHint      = Color(0xFF94A3B8); // Slate-400

  // ── Border ────────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0); // Slate-200

  // ── Brand Gradient (Electric Blue → Indigo) ────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    colors: [electricBlue, indigoDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = brandGradient;

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFFFB923C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Category Colors ───────────────────────────────────────────────────────
  static const Color standardCategory = electricBlue;
  static const Color familyCategory   = Color(0xFFD97706); // Amber-600
  static const Color energyCategory   = Color(0xFF059669); // Emerald
  static const Color bestCategory     = violetAccent;

  // ── Quick Address Gradients ───────────────────────────────────────────────
  static const LinearGradient homeGradient = LinearGradient(
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
  );
  static const LinearGradient workGradient = LinearGradient(
    colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
  );
  static const LinearGradient favoriteGradient = LinearGradient(
    colors: [Color(0xFFffecd2), Color(0xFFfcb69f)],
  );

  // ── Shadows ───────────────────────────────────────────────────────────────
  static Color shadowLight  = Colors.black.withValues(alpha: 0.08);
  static Color shadowMedium = Colors.black.withValues(alpha: 0.16);
  static Color shadowDark   = Colors.black.withValues(alpha: 0.28);
}
