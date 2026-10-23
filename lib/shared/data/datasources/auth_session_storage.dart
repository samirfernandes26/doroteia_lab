import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/auth/domain/entities/user_entity.dart';
import '../models/api_user_model.dart';

abstract interface class AuthSessionStorage {
  Future<UserEntity?> readUser();

  Future<void> saveUser(UserEntity user);

  Future<void> clearUser();
}

class SharedPreferencesAuthSessionStorage implements AuthSessionStorage {
  SharedPreferencesAuthSessionStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _userKey = 'doroteia_lab.authenticated_user';

  final SharedPreferencesAsync _preferences;

  @override
  Future<UserEntity?> readUser() async {
    final serializedUser = await _preferences.getString(_userKey);
    if (serializedUser == null || serializedUser.isEmpty) return null;

    try {
      final decodedUser = jsonDecode(serializedUser);
      if (decodedUser is! Map<String, dynamic>) {
        throw const FormatException('Sessão salva inválida.');
      }

      return ApiUserModel.fromJson(decodedUser);
    } on FormatException {
      await clearUser();
      return null;
    }
  }

  @override
  Future<void> saveUser(UserEntity user) {
    return _preferences.setString(
      _userKey,
      jsonEncode({'id': user.id, 'email': user.email, 'name': user.name}),
    );
  }

  @override
  Future<void> clearUser() => _preferences.remove(_userKey);
}
