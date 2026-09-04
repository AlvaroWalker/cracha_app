import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Tipos de erro de validação do crachá.
enum BadgeValidationError {
  nameRequired,
  nameTooShort,
  roleRequired,
  departmentRequired,
  departmentInvalid,
}

extension BadgeValidationErrorMessage on BadgeValidationError {
  String get message {
    switch (this) {
      case BadgeValidationError.nameRequired:
        return 'Informe o nome do funcionário';
      case BadgeValidationError.nameTooShort:
        return 'Nome deve ter pelo menos 3 caracteres';
      case BadgeValidationError.roleRequired:
        return 'Informe o cargo ou função';
      case BadgeValidationError.departmentRequired:
        return 'Selecione uma secretaria';
      case BadgeValidationError.departmentInvalid:
        return 'Secretaria inválida';
    }
  }
}

class BadgeData {
  String id;
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
  })  : id = id ?? _generateUuid(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  static String _generateUuid() {
    final rnd = Random.secure();
    final b = List<int>.generate(16, (_) => rnd.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final hex = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  /// Valida o crachá e retorna lista de erros (vazia = válido).
  List<BadgeValidationError> validate({List<String>? validDepartments}) {
    final errors = <BadgeValidationError>[];
    final n = name.trim();
    final r = role.trim();
    final d = department.trim();

    if (n.isEmpty) {
      errors.add(BadgeValidationError.nameRequired);
    } else if (n.length < 3) {
      errors.add(BadgeValidationError.nameTooShort);
    }
    if (r.isEmpty) errors.add(BadgeValidationError.roleRequired);
    if (d.isEmpty) {
      errors.add(BadgeValidationError.departmentRequired);
    } else if (validDepartments != null && !validDepartments.contains(d)) {
      errors.add(BadgeValidationError.departmentInvalid);
    }
    return errors;
  }

  /// Retorna true se o crachá é válido.
  bool isValid({List<String>? validDepartments}) => validate(validDepartments: validDepartments).isEmpty;

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

  Map<String, dynamic> toMapSemFoto() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'department': department,
      'photo': null,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BadgeData.fromMap(Map<String, dynamic> map) {
    String name = map['name'] ?? "";
    String role = map['role'] ?? "";
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

  void updateTimestamp() {
    updatedAt = DateTime.now();
  }

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
