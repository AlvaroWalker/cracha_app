import 'dart:convert';
import 'dart:typed_data';

class BadgeData {
  String id; // Identificador único
  String name;
  String role;
  String department;
  Uint8List? photo;
  DateTime createdAt;
  DateTime updatedAt;

  BadgeData({
    String? id,
    this.name = "",
    this.role = "",
    this.department = "SECRETARIA MUNICIPAL DE EDUCAÇÃO",
    this.photo,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Converte o objeto para um Map que pode ser salvo
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'department': department,
      'photo': photo != null ? base64Encode(photo!) : null,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Cria um objeto a partir de um Map
  factory BadgeData.fromMap(Map<String, dynamic> map) {
    String name = map['name'] ?? "";
    String role = map['role'] ?? "";

    // Garantir que nome e cargo estejam em maiúsculas
    return BadgeData(
      id: map['id'],
      name: name.toUpperCase(),
      role: role.toUpperCase(),
      department: map['department'],
      photo: map['photo'] != null ? base64Decode(map['photo']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Atualiza a data de modificação
  void updateTimestamp() {
    updatedAt = DateTime.now();
  }

  // Copia com novos valores
  BadgeData copyWith({
    String? name,
    String? role,
    String? department,
    Uint8List? photo,
  }) {
    return BadgeData(
      id: id,
      name: name != null ? name.toUpperCase() : this.name,
      role: role != null ? role.toUpperCase() : this.role,
      department: department ?? this.department,
      photo: photo ?? this.photo,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
