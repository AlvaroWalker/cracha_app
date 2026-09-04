import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/badge_data.dart';

class BadgeStorageService {
  static const String _badgeListKey = 'badge_list';

  // Método para salvar um novo crachá ou atualizar um existente
  static Future<bool> saveBadge(BadgeData badge) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Obter lista atual de crachás
      final badgeList = await getBadgeList();

      // Verificar se o crachá já existe na lista (para atualização)
      final existingIndex = badgeList.indexWhere((b) => b.id == badge.id);

      // Atualizar timestamp
      badge.updateTimestamp();

      if (existingIndex >= 0) {
        // Atualizar crachá existente
        badgeList[existingIndex] = badge;
      } else {
        // Adicionar novo crachá
        badgeList.add(badge);
      }

      // Salvar lista atualizada. Se estourar a cota do localStorage,
      // tenta descartar as fotos (mantém os dados) antes de desistir.
      bool saved;
      try {
        final badgeJsonList =
            badgeList.map((b) => jsonEncode(b.toMap())).toList();
        saved = await prefs.setStringList(_badgeListKey, badgeJsonList);
        if (!saved) throw Exception('setStringList retornou false');
      } catch (_) {
        // Cota excedida: salva sem as fotos (dados preservados)
        final badgeSemFoto =
            badgeList.map((b) => jsonEncode(b.toMapSemFoto())).toList();
        saved = await prefs.setStringList(_badgeListKey, badgeSemFoto);
      }
      return saved;
    } catch (e) {
      debugPrint('Erro ao salvar crachá: $e');
      return false;
    }
  }

  // Método para obter a lista de todos os crachás
  static Future<List<BadgeData>> getBadgeList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final badgeJsonList = prefs.getStringList(_badgeListKey) ?? [];

      return badgeJsonList
          .map((json) => BadgeData.fromMap(jsonDecode(json)))
          .toList()
        // Ordenar por data de atualização (mais recentes primeiro)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      debugPrint('Erro ao obter lista de crachás: $e');
      return [];
    }
  }

  // Substitui toda a lista local (espelho da nuvem)
  static Future<bool> replaceAll(List<BadgeData> badges) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Tenta salvar com fotos primeiro
      try {
        final badgeJsonList = badges.map((b) => jsonEncode(b.toMap())).toList();
        await prefs.setStringList(_badgeListKey, badgeJsonList);
        return true;
      } catch (_) {
        // Cota excedida: salva sem fotos (dados preservados)
        final badgeSemFoto = badges.map((b) => jsonEncode(b.toMapSemFoto())).toList();
        await prefs.setStringList(_badgeListKey, badgeSemFoto);
        return true;
      }
    } catch (e) {
      debugPrint('Erro ao substituir lista local: $e');
      return false;
    }
  }

  // Método para obter um crachá específico pelo ID
  static Future<BadgeData?> getBadgeById(String id) async {
    try {
      final badgeList = await getBadgeList();
      return badgeList.firstWhere(
        (badge) => badge.id == id,
        orElse: () => throw Exception('Crachá não encontrado'),
      );
    } catch (e) {
      debugPrint('Erro ao obter crachá por ID: $e');
      return null;
    }
  }

  // Método para excluir um crachá pelo ID
  static Future<bool> deleteBadge(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final badgeList = await getBadgeList();

      final filteredList = badgeList.where((badge) => badge.id != id).toList();

      if (filteredList.length < badgeList.length) {
        final badgeJsonList =
            filteredList.map((b) => jsonEncode(b.toMap())).toList();
        await prefs.setStringList(_badgeListKey, badgeJsonList);
        return true;
      }

      return false; // Crachá não encontrado
    } catch (e) {
      debugPrint('Erro ao excluir crachá: $e');
      return false;
    }
  }
}
