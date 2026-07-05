import 'package:flutter/material.dart';

/// Everything answers in under 400 ms — spring(mass 1, stiffness 300)
/// ≈ 320 ms settles the orb and sheet.
class Motion {
  static const Duration settle = Duration(milliseconds: 320);
  static const Duration quick = Duration(milliseconds: 160);
  static const Curve spring = Curves.easeOutCubic;
}

/// Route used for conversation and voice — content rises in on paper,
/// no hardware-style slide.
PageRoute<T> fadeUpRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: Motion.settle,
    reverseTransitionDuration: Motion.settle,
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Motion.spring);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
