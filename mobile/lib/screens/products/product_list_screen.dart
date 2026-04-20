import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../widgets/product_card.dart';

class ProductListScreen extends ConsumerWidget {
  final int categoryId;
  final String title;

  const ProductListScreen({super.key, required this.categoryId, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(categoryProductsProvider(categoryId));
    final favoriteIds = ref.watch(favoriteIdsProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: products.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('No products in this category'))
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: Responsive.gridDelegate(context),
                itemCount: list.length,
                itemBuilder: (_, i) => ProductCard(
                  product: list[i],
                  onTap: () => context.push('/products/${list[i].slug}'),
                  isFavorite: favoriteIds.contains(list[i].id),
                  onToggleFavorite: () => ref.read(favoriteIdsProvider.notifier).toggleFavorite(list[i].id),
                  onAddToCart: () async {
                    try {
                      await ref.read(cartProvider.notifier).addToCart(list[i].id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to cart!'), duration: Duration(seconds: 1)),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        String message = 'Something went wrong';
                        if (e is DioException && e.response?.data != null) {
                          final data = e.response!.data;
                          if (data is Map && data['message'] != null) message = data['message'];
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message), backgroundColor: AppColors.error, duration: const Duration(seconds: 2)),
                        );
                      }
                    }
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load products')),
      ),
    );
  }
}

