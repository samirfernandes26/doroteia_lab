import 'package:bcrypt/bcrypt.dart';

/// Gera um hash BCrypt seguro para [password].
String hashPassword(String password) {
  return BCrypt.hashpw(password, BCrypt.gensalt());
}

/// Verifica [password] contra um [hash] BCrypt.
bool verifyPassword(String password, String hash) {
  try {
    return BCrypt.checkpw(password, hash);
  } on Object {
    return false;
  }
}
