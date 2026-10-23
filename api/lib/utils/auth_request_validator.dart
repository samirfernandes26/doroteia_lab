import 'dart:convert';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Valida e normaliza os campos recebidos pelas rotas de autenticação.
abstract final class AuthRequestValidator {
  /// Valida e normaliza um endereço de e-mail.
  static String email(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      throw const RequestValidationException('Informe o e-mail.');
    }

    final email = value.trim().toLowerCase();
    if (email.length > 255 || !_emailPattern.hasMatch(email)) {
      throw const RequestValidationException('Informe um e-mail válido.');
    }
    return email;
  }

  /// Valida uma senha, exigindo força mínima durante o cadastro.
  static String password(Object? value, {bool forRegistration = false}) {
    if (value is! String || value.isEmpty) {
      throw const RequestValidationException('Informe a senha.');
    }
    if (forRegistration && value.length < 8) {
      throw const RequestValidationException(
        'A senha deve ter pelo menos 8 caracteres.',
      );
    }
    if (utf8.encode(value).length > 72) {
      throw const RequestValidationException(
        'A senha deve ter no máximo 72 bytes.',
      );
    }
    return value;
  }

  /// Valida e normaliza um nome opcional.
  static String? optionalName(Object? value) {
    if (value == null) return null;
    if (value is! String) {
      throw const RequestValidationException('O nome deve ser um texto.');
    }

    final name = value.trim();
    if (name.isEmpty) return null;
    if (name.length > 255) {
      throw const RequestValidationException(
        'O nome deve ter no máximo 255 caracteres.',
      );
    }
    return name;
  }
}

/// Erro causado por um campo inválido na requisição.
class RequestValidationException implements Exception {
  /// Cria um erro de validação.
  const RequestValidationException(this.message);

  /// Mensagem segura que pode ser enviada ao cliente.
  final String message;
}
