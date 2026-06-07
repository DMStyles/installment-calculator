import 'package:flutter/material.dart';

/// Central design token system for Installment Hub.
/// All colors, borders, and input decorations flow from here —
/// ensuring perfect light/dark mode consistency with zero hardcoding.
class AppTheme {
  AppTheme._();

  // ─── Radius ────────────────────────────────────────────────────────────────
  static const double radius = 20.0;
  static const double radiusSmall = 12.0;
  static const double radiusPill = 100.0;

  // ─── Surface Colors ────────────────────────────────────────────────────────
  static Color card(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E2025)
        : Colors.white;
  }

  static Color cardAlt(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF252830)
        : const Color(0xFFF1F3F9);
  }

  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  // ─── Text Colors ───────────────────────────────────────────────────────────
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFE8EAED)
        : const Color(0xFF1A1C1E);
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF8E9099)
        : const Color(0xFF5E5E6E);
  }

  static Color textHint(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF5C5F6A)
        : const Color(0xFFACAEB8);
  }

  // ─── Border Colors ─────────────────────────────────────────────────────────
  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2E3036)
        : const Color(0xFFE0E2EC);
  }

  static Color borderStrong(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3A3D45)
        : const Color(0xFFCCCEDA);
  }

  // ─── Icon Background ───────────────────────────────────────────────────────
  static Color iconBg(BuildContext context, Color accent) =>
      accent.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.10);

  // ─── Input Decoration ──────────────────────────────────────────────────────
  static InputDecoration inputDecoration(
    BuildContext context, {
    String? hintText,
    String? prefixText,
    String? suffixText,
    Widget? suffixIcon,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: textHint(context), fontSize: 16),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textSecondary(context),
      ),
      suffixText: suffixText,
      suffixStyle: TextStyle(color: textSecondary(context), fontSize: 14),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: cardAlt(context),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: BorderSide(color: border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: BorderSide(color: primary, width: 2),
      ),
    );
  }

  // ─── Card Decoration ───────────────────────────────────────────────────────
  static BoxDecoration cardDecoration(
    BuildContext context, {
    Color? accentBorder,
    bool strong = false,
  }) {
    final borderColor = accentBorder != null
        ? accentBorder.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.35)
        : (strong ? borderStrong(context) : border(context));

    return BoxDecoration(
      color: card(context),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: accentBorder != null ? 1.5 : 1.0),
    );
  }

  // ─── Warning Container ─────────────────────────────────────────────────────
  static BoxDecoration warningDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: Colors.amber.withValues(alpha: isDark ? 0.08 : 0.10),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Colors.amber.withValues(alpha: isDark ? 0.18 : 0.30),
        width: 1.5,
      ),
    );
  }

  // ─── Primary ───────────────────────────────────────────────────────────────
  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
}
