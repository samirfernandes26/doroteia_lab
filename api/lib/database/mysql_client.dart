import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:mysql_client/mysql_client.dart';

/// Gerencia uma única conexão sob demanda com o banco MySQL.
class MySqlDatabaseClient {
  /// Cria um cliente com uma configuração explícita.
  MySqlDatabaseClient({
    required String host,
    required int port,
    required String user,
    required String password,
    required String database,
  }) : _host = host,
       _port = port,
       _user = user,
       _password = password,
       _database = database;

  /// Cria um cliente a partir do processo e do arquivo [envFile].
  ///
  /// Valores definidos no ambiente do processo têm precedência sobre o
  /// arquivo local.
  factory MySqlDatabaseClient.fromEnvironment({String envFile = '.env'}) {
    final dotenv = DotEnv(quiet: true)..load([envFile]);

    String readRequired(String key) {
      final platformValue = Platform.environment[key]?.trim();
      final fileValue = dotenv[key]?.trim();
      final value = platformValue != null && platformValue.isNotEmpty
          ? platformValue
          : fileValue;

      if (value == null || value.isEmpty) {
        throw DatabaseConfigurationException(
          'A variável de ambiente $key não foi configurada.',
        );
      }

      return value;
    }

    final rawPort = readRequired('DB_PORT');
    final port = int.tryParse(rawPort);
    if (port == null || port < 1 || port > 65535) {
      throw const DatabaseConfigurationException(
        'DB_PORT deve ser um número entre 1 e 65535.',
      );
    }

    return MySqlDatabaseClient(
      host: readRequired('DB_HOST'),
      port: port,
      user: readRequired('DB_USER'),
      password: readRequired('DB_PASSWORD'),
      database: readRequired('DB_NAME'),
    );
  }

  final String _host;
  final int _port;
  final String _user;
  final String _password;
  final String _database;

  MySQLConnection? _connection;

  /// Indica se existe uma conexão ativa com o banco.
  bool get isConnected => _connection?.connected ?? false;

  /// Retorna a conexão ativa.
  ///
  /// Lança um [StateError] quando [open] ainda não foi chamado.
  MySQLConnection get connection {
    final activeConnection = _connection;
    if (activeConnection == null || !activeConnection.connected) {
      throw StateError(
        'A conexão com o MySQL ainda não foi aberta. Chame open() primeiro.',
      );
    }
    return activeConnection;
  }

  /// Abre a conexão ou reutiliza a conexão ativa.
  Future<MySQLConnection> open() async {
    if (isConnected) return connection;

    MySQLConnection? newConnection;
    try {
      newConnection = await MySQLConnection.createConnection(
        host: _host,
        port: _port,
        userName: _user,
        password: _password,
        databaseName: _database,
        secure: false,
      );
      await newConnection.connect();
      _connection = newConnection;
      return newConnection;
    } on Object catch (error, stackTrace) {
      if (newConnection?.connected ?? false) {
        try {
          await newConnection!.close();
        } on Object {
          // Preserva o erro original da tentativa de conexão.
        }
      }
      _connection = null;
      throw DatabaseConnectionException(
        'Não foi possível conectar ao MySQL em $_host:$_port/$_database.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fecha a conexão ativa e libera os recursos associados.
  Future<void> close() async {
    final activeConnection = _connection;
    if (activeConnection == null || !activeConnection.connected) {
      _connection = null;
      return;
    }

    try {
      await activeConnection.close();
    } on Object catch (error, stackTrace) {
      throw DatabaseConnectionException(
        'Não foi possível fechar a conexão com o MySQL.',
        cause: error,
        stackTrace: stackTrace,
      );
    } finally {
      _connection = null;
    }
  }
}

/// Erro causado por configuração ausente ou inválida do banco.
class DatabaseConfigurationException implements Exception {
  /// Cria um erro de configuração com uma mensagem segura.
  const DatabaseConfigurationException(this.message);

  /// Descrição do erro de configuração.
  final String message;

  @override
  String toString() => 'DatabaseConfigurationException: $message';
}

/// Erro ao abrir ou fechar uma conexão com o banco.
class DatabaseConnectionException implements Exception {
  /// Cria um erro de conexão sem incluir as credenciais na mensagem.
  const DatabaseConnectionException(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  /// Descrição segura do erro.
  final String message;

  /// Erro original retornado pelo cliente MySQL.
  final Object? cause;

  /// Stack trace capturado na operação original.
  final StackTrace? stackTrace;

  @override
  String toString() => 'DatabaseConnectionException: $message';
}
