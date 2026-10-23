import 'package:equatable/equatable.dart';

/// Usuário persistido e retornado pela API.
class User extends Equatable {
  /// Cria um usuário.
  const User({
    required this.id,
    required this.email,
    required this.createdAt,
    this.name,
  });

  /// Cria um usuário a partir de uma linha retornada pelo MySQL.
  factory User.fromDatabaseRow(Map<String, String?> row) {
    final id = row['id'];
    final email = row['email'];
    final rawCreatedAt = row['created_at'];
    final createdAt = rawCreatedAt == null
        ? null
        : DateTime.tryParse(rawCreatedAt);

    if (id == null || email == null || createdAt == null) {
      throw const FormatException('Dados de usuário inválidos no banco.');
    }

    return User(
      id: id,
      email: email,
      name: row['name'],
      createdAt: createdAt,
    );
  }

  /// Identificador UUID do usuário.
  final String id;

  /// E-mail normalizado do usuário.
  final String email;

  /// Nome opcional do usuário.
  final String? name;

  /// Data de criação do usuário.
  final DateTime createdAt;

  /// Converte o usuário para o formato público da API.
  Map<String, Object?> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, email, name, createdAt];
}
