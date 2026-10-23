import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/calculator/presentation/pages/home_page.dart';
import '../../features/catalog/presentation/pages/catalog_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final repository = ref.watch(authRepositoryProvider);
  final currentUser = authState.isLoading
      ? repository.currentUser
      : authState.valueOrNull;

  final router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = currentUser != null;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !isOnLogin) return '/login';
      if (isAuthenticated && isOnLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/catalog',
        name: 'catalog',
        builder: (context, state) => const CatalogPage(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
