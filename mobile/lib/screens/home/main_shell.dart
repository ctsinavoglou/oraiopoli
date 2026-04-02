import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static int _indexOf(String location) {
    if (location.startsWith('/categories') || location.startsWith('/category/') || location.startsWith('/products/category/')) return 1;
    if (location == '/favorites') return 2;
    if (location.startsWith('/cart') || location.startsWith('/checkout')) return 3;
    if (location.startsWith('/profile') || location.startsWith('/orders')) return 4;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(cartProvider.notifier).loadCart();
      ref.read(favoriteIdsProvider.notifier).loadFavoriteIds();
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final cartItemCount = ref.watch(cartProvider).valueOrNull?.totalItems ?? 0;

    return Scaffold(
      body: widget.child,
      // ...existing code...
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexOf(location),
        onTap: (i) {
          switch (i) {
            case 0: context.go('/');
            case 1: context.go('/categories');
            case 2: context.go('/favorites');
            case 3: context.go('/cart');
            case 4: context.go('/profile');
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.category_outlined), activeIcon: Icon(Icons.category), label: 'Categories'),
          const BottomNavigationBarItem(icon: Icon(Icons.favorite_border), activeIcon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: cartItemCount > 0,
              backgroundColor: Colors.red,
              label: Text('$cartItemCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: cartItemCount > 0,
              backgroundColor: Colors.red,
              label: Text('$cartItemCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

