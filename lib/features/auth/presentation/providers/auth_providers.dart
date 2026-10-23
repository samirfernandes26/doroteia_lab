import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/datasources/api_auth_datasource.dart';
import '../../../../shared/data/datasources/auth_session_storage.dart';
import '../../../../shared/data/repositories/api_auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

const authApiBaseUrl = 'http://localhost:8081';

final apiAuthDatasourceProvider = Provider<ApiAuthDatasource>((ref) {
  final datasource = ApiAuthDatasource(baseUrl: authApiBaseUrl);
  ref.onDispose(datasource.close);
  return datasource;
});

final authSessionStorageProvider = Provider<AuthSessionStorage>((ref) {
  return SharedPreferencesAuthSessionStorage();
});

final restoredAuthUserProvider = Provider<UserEntity?>((ref) => null);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repository = ApiAuthRepository(
    ref.watch(apiAuthDatasourceProvider),
    ref.watch(authSessionStorageProvider),
    initialUser: ref.watch(restoredAuthUserProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

final authStateProvider = StreamProvider<UserEntity?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
      return AuthController(ref.watch(authRepositoryProvider));
    });

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AsyncValue.data(null));

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.signInWithEmail(email: email, password: password);
    });
  }

  Future<void> signUp({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.signUpWithEmail(email: email, password: password);
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.signOut();
    });
  }
}
