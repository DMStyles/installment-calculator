import 'package:flutter/material.dart';

class PixelPageRoute<T> extends PageRouteBuilder<T> {
  PixelPageRoute({required WidgetBuilder builder, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Material You Style Zoom/Scale-Fade transition
            final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.fastOutSlowIn,
              ),
            );

            final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
            );

            // Exit transition for the page underneath
            final exitScaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.fastOutSlowIn,
              ),
            );

            final exitFadeAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeOut,
              ),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: AnimatedBuilder(
                  animation: secondaryAnimation,
                  builder: (context, childWidget) {
                    return FadeTransition(
                      opacity: exitFadeAnimation,
                      child: ScaleTransition(
                        scale: exitScaleAnimation,
                        child: childWidget,
                      ),
                    );
                  },
                  child: child,
                ),
              ),
            );
          },
        );
}
