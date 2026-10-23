import 'dart:io';

import 'package:api/database/mysql_client.dart';
import 'package:api/http/api_response.dart';
import 'package:api/repositories/user_repository.dart';
import 'package:api/utils/auth_request_validator.dart';
import 'package:api/utils/password_utils.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:uuid/uuid.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return ApiResponse.error(
      statusCode: HttpStatus.methodNotAllowed,
      code: 'method_not_allowed',
      message: 'Use o método POST.',
      headers: {HttpHeaders.allowHeader: HttpMethod.post.value},
    );
  }

  try {
    final payload = await _readJsonObject(context);
    final email = AuthRequestValidator.email(payload['email']);
    final password = AuthRequestValidator.password(payload['password']);
    final authentication = await context
        .read<UserRepository>()
        .findAuthenticationByEmail(email);

    if (authentication == null ||
        !verifyPassword(password, authentication.passwordHash)) {
      return _invalidCredentials();
    }

    return ApiResponse.success(
      message: 'Login realizado com sucesso.',
      data: {
        'user': authentication.user.toJson(),
        'token': const Uuid().v4(),
      },
    );
  } on FormatException {
    return ApiResponse.error(
      statusCode: HttpStatus.badRequest,
      code: 'invalid_json',
      message: 'Envie um objeto JSON válido.',
    );
  } on RequestValidationException catch (error) {
    return ApiResponse.error(
      statusCode: HttpStatus.badRequest,
      code: 'validation_error',
      message: error.message,
    );
  } on DatabaseConfigurationException {
    return _databaseConfigurationError();
  } on DatabaseConnectionException {
    return _databaseUnavailable();
  } on UserRepositoryException {
    return _internalError();
  } on Object {
    return _internalError();
  }
}

Future<Map<String, dynamic>> _readJsonObject(RequestContext context) async {
  final body = await context.request.json();
  if (body is! Map<String, dynamic>) {
    throw const RequestValidationException(
      'O corpo da requisição deve ser um objeto JSON.',
    );
  }
  return body;
}

Response _invalidCredentials() {
  return ApiResponse.error(
    statusCode: HttpStatus.unauthorized,
    code: 'invalid_credentials',
    message: 'E-mail ou senha inválidos.',
  );
}

Response _databaseConfigurationError() {
  return ApiResponse.error(
    statusCode: HttpStatus.internalServerError,
    code: 'database_configuration_error',
    message: 'A configuração do banco de dados está inválida.',
  );
}

Response _databaseUnavailable() {
  return ApiResponse.error(
    statusCode: HttpStatus.serviceUnavailable,
    code: 'database_unavailable',
    message: 'O banco de dados está temporariamente indisponível.',
  );
}

Response _internalError() {
  return ApiResponse.error(
    statusCode: HttpStatus.internalServerError,
    code: 'internal_error',
    message: 'Não foi possível concluir o login.',
  );
}
