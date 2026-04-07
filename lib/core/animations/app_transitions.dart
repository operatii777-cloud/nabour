import 'package:flutter/material.dart';

/// Tranziții custom pentru Navigator.push/pushReplacement în toată aplicația.
/// Înlocuiește MaterialPageRoute standard.
class AppTransitions {
  AppTransitions._();

  /// Slide de jos în sus — pentru bottom sheets și ecrane modale (ride request, summary)
  static Route<T> slideUp<T>(Widget page) => PageRouteBuilder<T>(
        pageBuilder: (_, animation, __) => page,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );

  /// Slide lateral — navigație standard între ecrane
  static Route<T> slideRight<T>(Widget page) => PageRouteBuilder<T>(
        pageBuilder: (_, animation, __) => page,
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );

  /// Fade — pentru overlay-uri, ecrane informaționale
  static Route<T> fade<T>(Widget page) => PageRouteBuilder<T>(
        pageBuilder: (_, animation, __) => page,
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      );

  /// Scale + Fade — pentru confirmări importante (booking confirmat)
  static Route<T> scaleUp<T>(Widget page) => PageRouteBuilder<T>(
        pageBuilder: (_, animation, __) => page,
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) => ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(opacity: animation, child: child),
        ),
      );
}
