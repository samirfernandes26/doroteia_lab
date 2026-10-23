import 'package:dart_frog/dart_frog.dart';

/// Cria respostas JSON consistentes para todas as rotas da API.
abstract final class ApiResponse {
  /// Cria uma resposta de sucesso.
  static Response success({
    required Object? data,
    int statusCode = 200,
    String? message,
  }) {
    return Response.json(
      statusCode: statusCode,
      body: {
        'success': true,
        if (message != null) 'message': message,
        'data': data,
      },
    );
  }

  /// Cria uma resposta de erro sem expor detalhes internos.
  static Response error({
    required int statusCode,
    required String code,
    required String message,
    Map<String, Object> headers = const {},
  }) {
    return Response.json(
      statusCode: statusCode,
      headers: headers,
      body: {
        'success': false,
        'error': {
          'code': code,
          'message': message,
        },
      },
    );
  }
}
