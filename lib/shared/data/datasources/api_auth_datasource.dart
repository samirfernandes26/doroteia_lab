import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../features/auth/domain/entities/user_entity.dart';
import '../exceptions/api_auth_exception.dart';
import '../models/api_user_model.dart';

class ApiAuthDatasource {
  ApiAuthDatasource({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 10),
  }) : baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
       client = client ?? http.Client();

  final String baseUrl;
  final http.Client client;
  final Duration requestTimeout;

  Future<UserEntity> signIn({required String email, required String password}) {
    return _authenticate(
      path: '/auth/login',
      payload: {'email': email.trim(), 'password': password},
    );
  }

  Future<UserEntity> signUp({
    required String email,
    required String password,
    String? name,
  }) {
    return _authenticate(
      path: '/auth/register',
      payload: {
        'email': email.trim(),
        'password': password,
        if (name != null) 'name': name.trim(),
      },
    );
  }

  Future<UserEntity> _authenticate({
    required String path,
    required Map<String, Object?> payload,
  }) async {
    late http.Response response;
    try {
      response = await client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(requestTimeout);
    } on TimeoutException {
      throw const ApiAuthException(
        'A API demorou para responder. Tente novamente.',
        code: 'request_timeout',
      );
    } on http.ClientException {
      throw const ApiAuthException(
        'Não foi possível conectar à API. Verifique se ela está ativa.',
        code: 'connection_error',
      );
    }

    final body = _decodeBody(response);
    final isSuccessful =
        response.statusCode >= 200 && response.statusCode < 300;

    if (!isSuccessful) {
      final error = body?['error'];
      final errorMap = error is Map<String, dynamic> ? error : null;
      final message = errorMap?['message'];
      final code = errorMap?['code'];

      throw ApiAuthException(
        message is String && message.isNotEmpty
            ? message
            : 'A API retornou o erro ${response.statusCode}.',
        code: code is String ? code : null,
        statusCode: response.statusCode,
      );
    }

    final data = body?['data'];
    final dataMap = data is Map<String, dynamic> ? data : null;
    final user = dataMap?['user'];
    if (user is! Map<String, dynamic>) {
      throw const ApiAuthException(
        'A API retornou uma resposta inválida.',
        code: 'invalid_response',
      );
    }

    try {
      return ApiUserModel.fromJson(user);
    } on FormatException {
      throw const ApiAuthException(
        'A API retornou dados de usuário inválidos.',
        code: 'invalid_response',
      );
    }
  }

  Map<String, dynamic>? _decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;

    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        throw const ApiAuthException(
          'A API retornou uma resposta inválida.',
          code: 'invalid_response',
        );
      }
      return null;
    }
  }

  void close() {
    client.close();
  }
}
