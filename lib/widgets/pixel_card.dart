import 'package:flutter/material.dart';
import '../app_theme.dart';

/// A themed card with automatic light/dark background, border, and radius.
/// Optionally accepts an [accentColor] for a colored border (provider cards).
class PixelCard extends StatelessWidget {
  const PixelCard({
    super.key,
    required this.child,
    this.accentColor,
    this.padding = const EdgeInsets.all(20),
    this.clipBehavior = Clip.hardEdge,
    this.strong = false,
  });

  final Widget child;
  final Color? accentColor;
  final EdgeInsetsGeometry padding;
  final Clip clipBehavior;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: clipBehavior,
      decoration: AppTheme.cardDecoration(
        context,
        accentBorder: accentColor,
        strong: strong,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
