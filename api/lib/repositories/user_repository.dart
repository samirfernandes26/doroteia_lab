import 'package:api/database/mysql_client.dart';
import 'package:api/models/user.dart';
import 'package:mysql_client/exception.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:uuid/uuid.dart';

/// Dados privados usados somente durante a verificação de credenciais.
class UserAuthenticationData {
  /// Cria os dados de autenticação de um usuário.
  const UserAuthenticationData({
    required this.user,
    required this.passwordHash,
  });

  /// Usuário sem informações sensíveis.
  final User user;

  /// Hash BCrypt armazenado no banco.
  final String passwordHash;
}

/// Acesso aos dados de usuários armazenados no MySQL.
class UserRepository {
  /// Cria o repositório com seu cliente de banco.
  UserRepository(MySqlDatabaseClient database, {Uuid? uuid})
    : _database = database,
      _uuid = uuid ?? const Uuid();

  final MySqlDatabaseClient _database;
  final Uuid _uuid;

  /// Busca um usuário pelo e-mail normalizado.
  Future<User?> findByEmail(String email) {
    return _withConnection('buscar o usuário', (connection) async {
      final result = await connection.execute(
        '''
SELECT id, email, name, created_at
FROM users
WHERE email = :email
LIMIT 1
''',
        {'email': email.trim().toLowerCase()},
      );

      if (result.numOfRows == 0) return null;
      return User.fromDatabaseRow(result.rows.first.assoc());
    });
  }

  /// Busca o usuário e seu hash para o processo interno de login.
  Future<UserAuthenticationData?> findAuthenticationByEmail(String email) {
    return _withConnection('buscar as credenciais', (connection) async {
      final result = await connection.execute(
        '''
SELECT id, email, name, created_at, password_hash
FROM users
WHERE email = :email
LIMIT 1
''',
        {'email': email.trim().toLowerCase()},
      );

      if (result.numOfRows == 0) return null;

      final row = result.rows.first.assoc();
      final passwordHash = row['password_hash'];
      if (passwordHash == null || passwordHash.isEmpty) {
        throw const FormatException('Hash de senha ausente no banco.');
      }

      return UserAuthenticationData(
        user: User.fromDatabaseRow(row),
        passwordHash: passwordHash,
      );
    });
  }

  /// Persiste e retorna um novo usuário.
  Future<User> createUser({
    required String email,
    required String passwordHash,
    String? name,
  }) {
    return _withConnection('criar o usuário', (connection) async {
      final id = _uuid.v4();
      final normalizedEmail = email.trim().toLowerCase();

      try {
        await connection.execute(
          '''
INSERT INTO users (id, email, password_hash, name)
VALUES (:id, :email, :passwordHash, :name)
''',
          {
            'id': id,
            'email': normalizedEmail,
            'passwordHash': passwordHash,
            'name': name,
          },
        );
      } on MySQLServerException catch (error) {
        if (error.errorCode == 1062) {
          throw UserAlreadyExistsException(normalizedEmail);
        }
        rethrow;
      }

      final result = await connection.execute(
        '''
SELECT id, email, name, created_at
FROM users
WHERE id = :id
LIMIT 1
''',
        {'id': id},
      );

      if (result.numOfRows == 0) {
        throw StateError('O usuário criado não foi encontrado.');
      }
      return User.fromDatabaseRow(result.rows.first.assoc());
    });
  }

  Future<T> _withConnection<T>(
    String operation,
    Future<T> Function(MySQLConnection connection) action,
  ) async {
    try {
      final connection = await _database.open();
      return await action(connection);
    } on UserAlreadyExistsException {
      rethrow;
    } on DatabaseConnectionException {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw UserRepositoryException(
        'Não foi possível $operation.',
        cause: error,
        stackTrace: stackTrace,
      );
    } finally {
      if (_database.isConnected) {
        await _database.close();
      }
    }
  }
}

/// Erro de conflito quando o e-mail já está cadastrado.
class UserAlreadyExistsException implements Exception {
  /// Cria o erro para [email].
  const UserAlreadyExistsException(this.email);

  /// E-mail que causou o conflito.
  final String email;
}

/// Erro interno ao acessar os dados de usuários.
class UserRepositoryException implements Exception {
  /// Cria um erro de repositório sem expor detalhes no texto público.
  const UserRepositoryException(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  /// Descrição segura da operação que falhou.
  final String message;

  /// Erro original.
  final Object? cause;

  /// Stack trace do erro original.
  final StackTrace? stackTrace;
}
