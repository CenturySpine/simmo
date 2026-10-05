import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The font bundled in `assets/fonts` (Plus Jakarta Sans, OFL).
const String appFontFamily = 'PlusJakartaSans';

/// Corner radii: one value per kind of element, used everywhere.
abstract final class AppRadius {
  /// Small tiles, pills, thumbnails.
  static const double small = 10;

  /// Buttons, fields, segmented controls.
  static const double control = 14;

  /// Cards.
  static const double card = 20;

  /// Dialogs and bottom sheets.
  static const double sheet = 28;
}

/// Builds the app theme: every Material component the app uses is styled
/// here, so screens only pick widgets, never colours or shapes.
ThemeData buildAppTheme() {
  const colorScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.primary,
    onSecondary: AppColors.onPrimary,
    secondaryContainer: AppColors.primaryContainer,
    onSecondaryContainer: AppColors.onPrimaryContainer,
    error: AppColors.danger,
    onError: AppColors.onPrimary,
    errorContainer: AppColors.dangerContainer,
    onErrorContainer: AppColors.onDangerContainer,
    surface: AppColors.background,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerLowest: AppColors.surface,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surface,
    surfaceContainerHighest: AppColors.surfaceMuted,
    surfaceTint: Colors.transparent,
    outline: AppColors.border,
    outlineVariant: AppColors.border,
    inverseSurface: AppColors.text,
    onInverseSurface: AppColors.surface,
    shadow: AppColors.text,
    scrim: AppColors.text,
  );

  TextStyle style(
    double size,
    FontWeight weight, {
    double height = 1.35,
    double spacing = 0,
    Color color = AppColors.text,
  }) => TextStyle(
    fontFamily: appFontFamily,
    fontSize: size,
    height: height,
    fontWeight: weight,
    letterSpacing: spacing,
    color: color,
  );

  final textTheme = TextTheme(
    displaySmall: style(36, FontWeight.w800, height: 1.1, spacing: -0.8),
    headlineLarge: style(32, FontWeight.w800, height: 1.15, spacing: -0.6),
    headlineMedium: style(28, FontWeight.w800, height: 1.15, spacing: -0.5),
    headlineSmall: style(24, FontWeight.w700, height: 1.2, spacing: -0.3),
    titleLarge: style(20, FontWeight.w700, height: 1.25, spacing: -0.2),
    titleMedium: style(17, FontWeight.w700, height: 1.3, spacing: -0.1),
    titleSmall: style(15, FontWeight.w600, height: 1.3),
    bodyLarge: style(17, FontWeight.w400, height: 1.45),
    bodyMedium: style(15, FontWeight.w400, height: 1.45),
    bodySmall: style(13, FontWeight.w500, color: AppColors.textSecondary),
    labelLarge: style(15, FontWeight.w600, height: 1.2),
    labelMedium: style(13, FontWeight.w600, color: AppColors.textSecondary),
    labelSmall: style(11, FontWeight.w700, spacing: 0.6),
  );

  final controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.control),
  );
  const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
  const buttonMinSize = Size(48, 52);
  final buttonText = style(16, FontWeight.w700, height: 1.2);

  OutlineInputBorder fieldBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    fontFamily: appFontFamily,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    textTheme: textTheme,
    iconTheme: const IconThemeData(color: AppColors.text, size: 22),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),

    // --- Buttons -----------------------------------------------------------
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: controlShape,
        padding: buttonPadding,
        minimumSize: buttonMinSize,
        textStyle: buttonText,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.textDisabled,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: controlShape,
        padding: buttonPadding,
        minimumSize: buttonMinSize,
        textStyle: buttonText,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        disabledForegroundColor: AppColors.textDisabled,
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: style(15, FontWeight.w700, height: 1.2),
        shape: controlShape,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    ),

    // --- Surfaces ----------------------------------------------------------
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      toolbarHeight: 60,
      titleTextStyle: style(20, FontWeight.w800, spacing: -0.3),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      ),
      titleTextStyle: style(20, FontWeight.w800, spacing: -0.2),
      contentTextStyle: style(15, FontWeight.w400, height: 1.45),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.text,
      contentTextStyle: style(15, FontWeight.w500, color: AppColors.surface),
      elevation: 0,
      shape: controlShape,
    ),

    // --- Inputs ------------------------------------------------------------
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceMuted,
      hoverColor: Colors.transparent,
      labelStyle: style(15, FontWeight.w500, color: AppColors.textSecondary),
      floatingLabelStyle: style(14, FontWeight.w700, color: AppColors.primary),
      hintStyle: style(15, FontWeight.w400, color: AppColors.textDisabled),
      helperStyle: style(12, FontWeight.w500, color: AppColors.textSecondary),
      errorStyle: style(12, FontWeight.w600, color: AppColors.danger),
      border: fieldBorder(Colors.transparent),
      enabledBorder: fieldBorder(Colors.transparent),
      disabledBorder: fieldBorder(Colors.transparent),
      focusedBorder: fieldBorder(AppColors.primary, 2),
      errorBorder: fieldBorder(AppColors.danger, 1.5),
      focusedErrorBorder: fieldBorder(AppColors.danger, 2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.primaryContainer,
      thumbColor: AppColors.primary,
      overlayColor: AppColors.primary.withValues(alpha: 0.12),
      valueIndicatorColor: AppColors.text,
      valueIndicatorTextStyle: style(
        13,
        FontWeight.w700,
        color: AppColors.surface,
      ),
      trackHeight: 6,
      activeTickMarkColor: Colors.transparent,
      inactiveTickMarkColor: Colors.transparent,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStateProperty.all(controlShape),
        side: WidgetStateProperty.all(
          const BorderSide(color: AppColors.border, width: 1.5),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primaryContainer
              : AppColors.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onPrimaryContainer
              : AppColors.textSecondary,
        ),
        textStyle: WidgetStateProperty.all(style(14, FontWeight.w700)),
        visualDensity: VisualDensity.compact,
      ),
    ),
    // Project tabs.
    chipTheme: ChipThemeData(
      shape: controlShape,
      side: const BorderSide(color: AppColors.border, width: 1.5),
      color: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primaryContainer
            : AppColors.surface,
      ),
      labelStyle: style(
        14,
        FontWeight.w700,
        color: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onPrimaryContainer
              : AppColors.textSecondary,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 18),
      deleteIconColor: AppColors.onPrimaryContainer,
      showCheckmark: false,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(AppColors.surface),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.textDisabled,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      shape: Border(),
      collapsedShape: Border(),
      tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      childrenPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
      iconColor: AppColors.textSecondary,
      collapsedIconColor: AppColors.textSecondary,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.primaryContainer,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.primary.withValues(alpha: 0.25),
      selectionHandleColor: AppColors.primary,
    ),
  );
}
