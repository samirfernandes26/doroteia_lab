import 'dart:convert';
import 'dart:io';

import 'package:api/models/user.dart';
import 'package:api/repositories/user_repository.dart';
import 'package:api/utils/password_utils.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/auth/register.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _FakeUserRepository implements UserRepository {
  User? existingUser;
  String? createdPasswordHash;

  @override
  Future<User?> findByEmail(String email) async => existingUser;

  @override
  Future<UserAuthenticationData?> findAuthenticationByEmail(String email) {
    throw UnimplementedError();
  }

  @override
  Future<User> createUser({
    required String email,
    required String passwordHash,
    String? name,
  }) async {
    createdPasswordHash = passwordHash;
    return User(
      id: 'user-id',
      email: email,
      name: name,
      createdAt: DateTime.utc(2026, 10, 22),
    );
  }
}

void main() {
  group('POST /auth/register', () {
    test('creates a user without exposing the password hash', () async {
      final repository = _FakeUserRepository();
      final context = _requestContext(
        repository,
        method: HttpMethod.post.value,
        body: {
          'email': 'USER@example.com',
          'password': 'senha123',
          'name': 'Usuário',
        },
      );

      final response = await route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      final data = body['data']! as Map<String, dynamic>;
      final user = data['user']! as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.created);
      expect(body['success'], isTrue);
      expect(user['email'], 'user@example.com');
      expect(user, isNot(contains('passwordHash')));
      expect(repository.createdPasswordHash, isNot('senha123'));
      expect(
        verifyPassword('senha123', repository.createdPasswordHash!),
        isTrue,
      );
    });

    test('returns 409 when the email already exists', () async {
      final repository = _FakeUserRepository()
        ..existingUser = User(
          id: 'existing-id',
          email: 'user@example.com',
          createdAt: DateTime.utc(2026, 10, 22),
        );
      final context = _requestContext(
        repository,
        method: HttpMethod.post.value,
        body: {
          'email': 'user@example.com',
          'password': 'senha123',
        },
      );

      final response = await route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.conflict);
      _expectError(
        body,
        code: 'email_already_registered',
        message: 'Já existe uma conta com este e-mail.',
      );
    });

    test(
      'returns a standardized validation error for a short password',
      () async {
        final context = _requestContext(
          _FakeUserRepository(),
          method: HttpMethod.post.value,
          body: {
            'email': 'user@example.com',
            'password': '1234567',
          },
        );

        final response = await route.onRequest(context);
        final body = jsonDecode(await response.body()) as Map<String, dynamic>;

        expect(response.statusCode, HttpStatus.badRequest);
        _expectError(
          body,
          code: 'validation_error',
          message: 'A senha deve ter pelo menos 8 caracteres.',
        );
      },
    );

    test('returns a validation error for an invalid email', () async {
      final context = _requestContext(
        _FakeUserRepository(),
        method: HttpMethod.post.value,
        body: {
          'email': 'invalid-email',
          'password': 'senha123',
        },
      );

      final response = await route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.badRequest);
      _expectError(
        body,
        code: 'validation_error',
        message: 'Informe um e-mail válido.',
      );
    });

    test('returns a standardized error for malformed JSON', () async {
      final context = _requestContext(
        _FakeUserRepository(),
        method: HttpMethod.post.value,
        rawBody: '{invalid-json',
      );

      final response = await route.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.badRequest);
      _expectError(
        body,
        code: 'invalid_json',
        message: 'Envie um objeto JSON válido.',
      );
    });

    test('rejects methods other than POST', () async {
      final context = _requestContext(
        _FakeUserRepository(),
        method: HttpMethod.get.value,
      );

      final response = await route.onRequest(context);

      expect(response.statusCode, HttpStatus.methodNotAllowed);
      expect(response.headers[HttpHeaders.allowHeader], 'POST');
    });
  });
}

RequestContext _requestContext(
  UserRepository repository, {
  required String method,
  Map<String, Object?>? body,
  String? rawBody,
}) {
  final context = _MockRequestContext();
  final request = Request(
    method,
    Uri.parse('http://localhost/auth/register'),
    headers: {HttpHeaders.contentTypeHeader: ContentType.json.mimeType},
    body: rawBody ?? (body == null ? null : jsonEncode(body)),
  );

  when(() => context.request).thenReturn(request);
  when(() => context.read<UserRepository>()).thenReturn(repository);
  return context;
}

void _expectError(
  Map<String, dynamic> body, {
  required String code,
  required String message,
}) {
  expect(body['success'], isFalse);
  expect(body['error'], {'code': code, 'message': message});
}
