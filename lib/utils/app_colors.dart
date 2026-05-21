import 'package:flutter/material.dart';

class AppColors {
  // Cores principais
  static const Color primaryColor = Color(0xFF0F5A29); // Verde Floresta Profundo (Prefeitura)
  static const Color secondaryColor = Color(0xFF2E7D32); // Verde Médio Corporativo
  static const Color accentColor = Color(0xFFD4AF37); // Dourado Elegante (Acentuação Premium)

  // Variações de tons
  static const Color lightGreen = Color(0xFFF0F7F1); // Fundo menta ultra suave
  static const Color mediumGreen = Color(0xFF81C784); // Destaque médio
  static const Color darkGreen = Color(0xFF0C3E1B); // Verde profundo para contrastes

  // Cores funcionais
  static const Color textColor = Color(0xFF1E293B); // Slate 800 (Leitura confortável)
  static const Color subtitleColor = Color(0xFF64748B); // Slate 500 (Legendas)
  static const Color backgroundColor = Color(0xFFF8FAF9); // Fundo principal off-white menta
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFEF4444); // Vermelho moderno

  // Efeito de sombra padrão premium
  static List<BoxShadow> defaultShadow = [
    BoxShadow(
      color: const Color(0xFF0F5A29).withValues(alpha: 0.06),
      spreadRadius: 0,
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: const Color(0xFF0F5A29).withValues(alpha: 0.04),
      spreadRadius: 0,
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
}
