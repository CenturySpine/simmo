import 'package:flutter/material.dart';

/// The Simmo palette (docs in AGENTS.md, "Design"). The only file allowed to
/// contain raw `Color(0x...)` values.
abstract final class AppColors {
  /// Page background.
  static const background = Color(0xFFF4F5FA);

  /// Cards, sheets, dialogs.
  static const surface = Color(0xFFFFFFFF);

  /// Input fills and quiet tiles sitting on a [surface].
  static const surfaceMuted = Color(0xFFF0F1F7);

  /// Hairlines: card outlines, dividers.
  static const border = Color(0xFFE3E5EF);

  static const text = Color(0xFF14172B);
  static const textSecondary = Color(0xFF5C6275);
  static const textDisabled = Color(0xFFA2A6B6);

  /// Brand blue: primary buttons, selection, links, focus. White on it: 5.9:1.
  static const primary = Color(0xFF2F54EB);
  static const onPrimary = Color(0xFFFFFFFF);

  /// Pale fill for selected rows, pills, icon tiles, and its text (7.5:1).
  static const primaryContainer = Color(0xFFEBEFFF);
  static const onPrimaryContainer = Color(0xFF1D39C4);

  /// Brand gradient (logo tile, hero).
  static const brandStart = primary;
  static const brandEnd = Color(0xFF1D39C4);

  /// Errors and destructive actions.
  static const danger = Color(0xFFCF2E3A);
  static const dangerContainer = Color(0xFFFDECEC);
  static const onDangerContainer = Color(0xFFB42328);

  /// Close to a limit (debt ratio above 33%). 5.3:1 on white.
  static const warning = Color(0xFFB54708);

  /// Positive outcome (e.g. an affordable loan).
  static const success = Color(0xFF0A7A47);
  static const successContainer = Color(0xFFE2F6EA);
}
