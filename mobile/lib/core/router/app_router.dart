import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/home/main_shell.dart';
import '../../screens/categories/categories_screen.dart';
import '../../screens/categories/category_detail_screen.dart';
import '../../screens/products/product_list_screen.dart';
import '../../screens/products/product_detail_screen.dart';
import '../../screens/cart/cart_screen.dart';
import '../../screens/checkout/checkout_screen.dart';
import '../../screens/orders/orders_screen.dart';
import '../../screens/orders/order_detail_screen.dart';
import '../../screens/profile/profile_screen.dart';

/// A [ChangeNotifier] that fires whenever the auth state changes,
/// so GoRouter re-evaluates its redirect without being recreated.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),
          GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
            path: '/category/:id',
            builder: (_, state) => CategoryDetailScreen(
              categoryId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/products/category/:id',
            builder: (_, state) => ProductListScreen(
              categoryId: int.parse(state.pathParameters['id']!),
              title: state.uri.queryParameters['title'] ?? 'Products',
            ),
          ),
          GoRoute(
            path: '/products/:slug',
            builder: (_, state) => ProductDetailScreen(slug: state.pathParameters['slug']!),
          ),
          GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
          GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
          GoRoute(
            path: '/orders/:id',
            builder: (_, state) => OrderDetailScreen(orderId: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoading = authState.isLoading;
      final user = authState.valueOrNull;
      final isOnSplash = state.matchedLocation == '/splash';
      final isOnAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (isLoading) return isOnSplash ? null : '/splash';
      if (user == null && !isOnAuth) return '/login';
      if (user != null && (isOnAuth || isOnSplash)) return '/';
      return null;
    },
  );
});

