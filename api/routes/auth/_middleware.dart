import 'package:api/database/mysql_client.dart';
import 'package:api/repositories/user_repository.dart';
import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler handler) {
  return handler.use(
    provider<UserRepository>(
      (_) => UserRepository(MySqlDatabaseClient.fromEnvironment()),
    ),
  );
}
