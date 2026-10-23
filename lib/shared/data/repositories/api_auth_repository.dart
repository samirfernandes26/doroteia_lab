import 'dart:async';

import '../../../features/auth/domain/entities/user_entity.dart';
import '../../../features/auth/domain/repositories/auth_repository.dart';
import '../datasources/api_auth_datasource.dart';
import '../datasources/auth_session_storage.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(
    this._datasource,
    this._sessionStorage, {
    UserEntity? initialUser,
  }) : _currentUser = initialUser;

  final ApiAuthDatasource _datasource;
  final AuthSessionStorage _sessionStorage;
  final StreamController<UserEntity?> _authStateController =
      StreamController<UserEntity?>.broadcast();

  UserEntity? _currentUser;

  @override
  UserEntity? get currentUser => _currentUser;

  @override
  Stream<UserEntity?> get authStateChanges async* {
    yield _currentUser;
    yield* _authStateController.stream;
  }

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final user = await _datasource.signIn(email: email, password: password);
    await _sessionStorage.saveUser(user);
    _setCurrentUser(user);
    return user;
  }

  @override
  Future<UserEntity> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final user = await _datasource.signUp(email: email, password: password);
    await _sessionStorage.saveUser(user);
    _setCurrentUser(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    try {
      await _sessionStorage.clearUser();
    } finally {
      _setCurrentUser(null);
    }
  }

  void _setCurrentUser(UserEntity? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  void dispose() {
    _authStateController.close();
  }
}
