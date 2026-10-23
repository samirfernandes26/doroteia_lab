import 'package:dart_frog/dart_frog.dart';

/// Adiciona os cabeçalhos CORS a todas as respostas da API e encerra os
/// preflights antes que eles cheguem às rotas.
Handler middleware(Handler handler) {
  return (context) async {
    if (context.request.method == HttpMethod.options) {
      return Response(
        statusCode: 204,
        headers: _corsHeaders,
      );
    }

    final response = await handler(context);
    return response.copyWith(
      headers: {
        ...response.headers,
        ..._corsHeaders,
      },
    );
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
};
