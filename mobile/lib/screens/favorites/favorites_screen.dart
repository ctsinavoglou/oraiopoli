import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/cart_provider.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});
  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(favoritesListProvider.notifier).loadFavorites());
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(favoritesListProvider);
    final favoriteIds = ref.watch(favoriteIdsProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favoritesAsync.when(
        data: (favorites) {
          // Filter out any that were optimistically removed
          final visibleFavorites = favorites.where((p) => favoriteIds.contains(p.id)).toList();

          if (visibleFavorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: AppColors.textHint.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('No favorites yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  const Text('Tap the heart on any product to save it here',
                      style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(favoritesListProvider.notifier).loadFavorites();
              await ref.read(favoriteIdsProvider.notifier).loadFavoriteIds();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: visibleFavorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final product = visibleFavorites[i];
                return GestureDetector(
                  onTap: () => context.push('/products/${product.slug}'),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: product.resolvedThumbnailUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: product.resolvedThumbnailUrl!,
                                    width: 70, height: 70, fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(width: 70, height: 70, color: AppColors.divider),
                                    errorWidget: (_, __, ___) => Container(width: 70, height: 70, color: AppColors.divider,
                                        child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textHint)),
                                  )
                                : Container(width: 70, height: 70, color: AppColors.divider,
                                    child: const Icon(Icons.shopping_bag_outlined, color: AppColors.textHint)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                if (product.categoryName != null)
                                  Text(product.categoryName!,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (product.hasDiscount) ...[
                                      Text('€${product.price.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: AppColors.textHint)),
                                      const SizedBox(width: 4),
                                      Text('€${product.discountPrice!.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accent)),
                                    ] else
                                      Text('€${product.price.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              if (product.inStock)
                                GestureDetector(
                                  onTap: () async {
                                    try {
                                      await ref.read(cartProvider.notifier).addToCart(product.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Added to cart!'), duration: Duration(seconds: 1)),
                                        );
                                      }
                                    } catch (_) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Failed to add to cart'), backgroundColor: AppColors.error),
                                        );
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 18),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  try {
                                    await ref.read(favoriteIdsProvider.notifier).toggleFavorite(product.id);
                                    // Reload the list after removing
                                    ref.read(favoritesListProvider.notifier).loadFavorites();
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Failed to remove'), backgroundColor: AppColors.error),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.favorite, color: AppColors.accent, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load favorites')),
      ),
    );
  }
}

