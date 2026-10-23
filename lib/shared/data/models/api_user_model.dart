import '../../../features/auth/domain/entities/user_entity.dart';

class ApiUserModel extends UserEntity {
  const ApiUserModel({required super.id, required super.email, super.name});

  factory ApiUserModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final email = json['email'];
    final name = json['name'];

    if (id is! String || id.isEmpty || email is! String || email.isEmpty) {
      throw const FormatException('Dados de usuário inválidos na resposta.');
    }
    if (name != null && name is! String) {
      throw const FormatException('Nome de usuário inválido na resposta.');
    }

    return ApiUserModel(id: id, email: email, name: name as String?);
  }
}
