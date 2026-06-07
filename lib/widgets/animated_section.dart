import 'package:flutter/material.dart';

/// Smoothly animates showing/hiding a child widget with a size + fade transition.
/// Use this instead of bare `if (condition) child` for animated reveals.
class AnimatedSection extends StatelessWidget {
  const AnimatedSection({
    super.key,
    required this.visible,
    required this.child,
    this.duration = const Duration(milliseconds: 280),
    this.curve = Curves.easeInOutCubic,
  });

  final bool visible;
  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: curve,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: curve,
        switchOutCurve: curve,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: visible
            ? SizedBox(key: const ValueKey('shown'), width: double.infinity, child: child)
            : const SizedBox(key: ValueKey('hidden'), width: double.infinity, height: 0),
      ),
    );
  }
}
