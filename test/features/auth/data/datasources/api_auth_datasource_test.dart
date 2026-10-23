import 'dart:convert';

import 'package:doroteia_lab/shared/data/datasources/api_auth_datasource.dart';
import 'package:doroteia_lab/shared/data/exceptions/api_auth_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('ApiAuthDatasource', () {
    late _MockHttpClient client;

    setUp(() {
      client = _MockHttpClient();
    });

    test('realiza login e converte o usuário em uma resposta 200', () async {
      _respondWith(
        client,
        statusCode: 200,
        body: {
          'success': true,
          'data': {
            'user': {
              'id': 'user-id',
              'email': 'user@example.com',
              'name': 'User',
            },
            'token': 'temporary-token',
          },
        },
      );
      final datasource = _datasource(client);
      addTearDown(datasource.close);

      final user = await datasource.signIn(
        email: ' user@example.com ',
        password: 'senha123',
      );

      expect(user.id, 'user-id');
      expect(user.email, 'user@example.com');
      expect(user.name, 'User');
      verify(
        () => client.post(
          Uri.parse('http://localhost:8081/auth/login'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': 'user@example.com',
            'password': 'senha123',
          }),
        ),
      ).called(1);
    });

    test('realiza cadastro e converte o usuário em uma resposta 201', () async {
      _respondWith(
        client,
        statusCode: 201,
        body: {
          'success': true,
          'data': {
            'user': {
              'id': 'new-user-id',
              'email': 'new@example.com',
              'name': 'New User',
            },
          },
        },
      );
      final datasource = _datasource(client);
      addTearDown(datasource.close);

      final user = await datasource.signUp(
        email: 'new@example.com',
        password: 'senha123',
        name: 'New User',
      );

      expect(user.id, 'new-user-id');
      verify(
        () => client.post(
          Uri.parse('http://localhost:8081/auth/register'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': 'new@example.com',
            'password': 'senha123',
            'name': 'New User',
          }),
        ),
      ).called(1);
    });

    test('expõe credenciais inválidas retornadas com status 401', () async {
      _respondWithError(
        client,
        statusCode: 401,
        code: 'invalid_credentials',
        message: 'E-mail ou senha inválidos.',
      );
      final datasource = _datasource(client);
      addTearDown(datasource.close);

      await expectLater(
        datasource.signIn(email: 'user@example.com', password: 'incorreta'),
        throwsA(
          isA<ApiAuthException>()
              .having((error) => error.statusCode, 'statusCode', 401)
              .having((error) => error.code, 'code', 'invalid_credentials')
              .having(
                (error) => error.message,
                'message',
                'E-mail ou senha inválidos.',
              ),
        ),
      );
    });

    test('expõe e-mail já cadastrado retornado com status 409', () async {
      _respondWithError(
        client,
        statusCode: 409,
        code: 'email_already_registered',
        message: 'Já existe uma conta com este e-mail.',
      );
      final datasource = _datasource(client);
      addTearDown(datasource.close);

      await expectLater(
        datasource.signUp(email: 'user@example.com', password: 'senha123'),
        throwsA(
          isA<ApiAuthException>()
              .having((error) => error.statusCode, 'statusCode', 409)
              .having(
                (error) => error.code,
                'code',
                'email_already_registered',
              ),
        ),
      );
    });

    test('converte falha de conexão em erro legível para a UI', () async {
      when(
        () => client.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(http.ClientException('connection refused'));
      final datasource = _datasource(client);
      addTearDown(datasource.close);

      await expectLater(
        datasource.signIn(email: 'user@example.com', password: 'senha123'),
        throwsA(
          isA<ApiAuthException>()
              .having((error) => error.code, 'code', 'connection_error')
              .having(
                (error) => error.message,
                'message',
                contains('Não foi possível conectar'),
              ),
        ),
      );
    });

    test('converte timeout em erro legível para a UI', () async {
      when(
        () => client.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response('{}', 200);
      });
      final datasource = _datasource(
        client,
        requestTimeout: const Duration(milliseconds: 1),
      );
      addTearDown(datasource.close);

      await expectLater(
        datasource.signIn(email: 'user@example.com', password: 'senha123'),
        throwsA(
          isA<ApiAuthException>()
              .having((error) => error.code, 'code', 'request_timeout')
              .having((error) => error.message, 'message', contains('demorou')),
        ),
      );
    });

    test('rejeita JSON inválido em uma resposta de sucesso', () async {
      when(
        () => client.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('{invalid-json', 200));
      final datasource = _datasource(client);
      addTearDown(datasource.close);

      await expectLater(
        datasource.signIn(email: 'user@example.com', password: 'senha123'),
        throwsA(
          isA<ApiAuthException>()
              .having((error) => error.code, 'code', 'invalid_response')
              .having(
                (error) => error.message,
                'message',
                'A API retornou uma resposta inválida.',
              ),
        ),
      );
    });
  });
}

ApiAuthDatasource _datasource(
  http.Client client, {
  Duration requestTimeout = const Duration(seconds: 10),
}) {
  return ApiAuthDatasource(
    baseUrl: 'http://localhost:8081/',
    client: client,
    requestTimeout: requestTimeout,
  );
}

void _respondWith(
  _MockHttpClient client, {
  required int statusCode,
  required Map<String, Object?> body,
}) {
  when(
    () => client.post(
      any(),
      headers: any(named: 'headers'),
      body: any(named: 'body'),
    ),
  ).thenAnswer((_) async => http.Response(jsonEncode(body), statusCode));
}

void _respondWithError(
  _MockHttpClient client, {
  required int statusCode,
  required String code,
  required String message,
}) {
  _respondWith(
    client,
    statusCode: statusCode,
    body: {
      'success': false,
      'error': {'code': code, 'message': message},
    },
  );
}
