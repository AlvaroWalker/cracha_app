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

      // Salvar lista atualizada
      final badgeJsonList =
          badgeList.map((b) => jsonEncode(b.toMap())).toList();
      await prefs.setStringList(_badgeListKey, badgeJsonList);
      return true;
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
