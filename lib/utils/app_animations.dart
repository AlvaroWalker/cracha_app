import 'package:flutter/material.dart';

class AppAnimations {
  // Duração padrão das animações
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);

  // Curvas de animação
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve sharpCurve = Curves.easeOutQuint;

  // Transições de página personalizadas
  static PageRouteBuilder<T> fadeTransition<T>(Widget page,
      [Duration? duration]) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? defaultDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  static PageRouteBuilder<T> slideTransition<T>(Widget page,
      {SlideDirection direction = SlideDirection.right, Duration? duration}) {
    Offset beginOffset;

    switch (direction) {
      case SlideDirection.right:
        beginOffset = const Offset(1.0, 0.0);
        break;
      case SlideDirection.left:
        beginOffset = const Offset(-1.0, 0.0);
        break;
      case SlideDirection.up:
        beginOffset = const Offset(0.0, -1.0);
        break;
      case SlideDirection.down:
        beginOffset = const Offset(0.0, 1.0);
        break;
    }

    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? defaultDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: defaultCurve,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  static PageRouteBuilder<T> scaleTransition<T>(Widget page,
      [Duration? duration]) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? defaultDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: defaultCurve,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity:
                Tween<double>(begin: 0.5, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  // Implementação simplificada sem FutureBuilder ou AnimatedBuilder
  // Usa AnimatedOpacity diretamente para garantir visibilidade
  static Widget animatedListItem(Widget child, int index, {Duration? delay}) {
    return AnimatedOpacity(
      opacity: 1.0, // Sempre visível
      duration: defaultDuration,
      curve: sharpCurve,
      child: child,
    );
  }

  // Implementação simplificada sem StatefulBuilder
  static Widget fadeInTransition(Widget child,
      {Duration? delay, Duration? duration}) {
    // Retorna o widget diretamente sem animação para garantir que seja visível
    return child;
  }
}

// Enum para direção do slide
enum SlideDirection {
  right,
  left,
  up,
  down,
}
