import 'package:flutter/material.dart';

/// All raw color constants for PoultryGuard Lite.
/// Never hardcode hex values in widgets — always reference this class.
abstract final class AppColors {
  // ── Primary — Amber Gold ──────────────────────────────────────────────────
  static const Color primary = Color(0xFFF4A900);
  static const Color onPrimary = Color(0xFF1A1200);
  static const Color primaryContainer = Color(0xFFFFDEA0);
  static const Color onPrimaryContainer = Color(0xFF271900);

  // ── Secondary — Forest Green ──────────────────────────────────────────────
  static const Color secondary = Color(0xFF2E7D32);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFB8F0BB);
  static const Color onSecondaryContainer = Color(0xFF00210A);

  // ── Error — Deep Red ──────────────────────────────────────────────────────
  static const Color error = Color(0xFFB71C1C);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFCDD2);
  static const Color onErrorContainer = Color(0xFF410002);

  // ── Surface / Background (Dark) ───────────────────────────────────────────
  static const Color surface = Color(0xFF121212);
  static const Color onSurface = Color(0xFFF5F0E8);
  static const Color surfaceContainerHigh = Color(0xFF1E1E1E);
  static const Color surfaceContainerLow = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF323232);

  // ── Outline ───────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF7A6128);
  static const Color outlineVariant = Color(0xFF4A3B10);

  // ── Semantic shortcuts ────────────────────────────────────────────────────
  static const Color healthy = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF4A900);
  static const Color critical = Color(0xFFB71C1C);
  static const Color unknown = Color(0xFF757575);
}
