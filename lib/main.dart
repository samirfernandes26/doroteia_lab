import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/auth/domain/entities/user_entity.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'shared/data/datasources/auth_session_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sessionStorage = SharedPreferencesAuthSessionStorage();
  UserEntity? restoredUser;

  try {
    restoredUser = await sessionStorage.readUser();
  } on Object {
    restoredUser = null;
  }

  runApp(
    ProviderScope(
      overrides: [
        authSessionStorageProvider.overrideWithValue(sessionStorage),
        restoredAuthUserProvider.overrideWithValue(restoredUser),
      ],
      child: const DoroteiaLabApp(),
    ),
  );
}
