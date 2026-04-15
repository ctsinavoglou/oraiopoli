import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String slug;
  const ProductDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(slug));
    final favoriteIds = ref.watch(favoriteIdsProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          productAsync.whenOrNull(
            data: (product) {
              final isFav = favoriteIds.contains(product.id);
              return IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? AppColors.accent : null),
                onPressed: () => ref.read(favoriteIdsProvider.notifier).toggleFavorite(product.id),
              );
            },
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: productAsync.when(
        data: (product) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              SizedBox(
                height: 300,
                width: double.infinity,
                child: product.resolvedThumbnailUrl != null
                    ? CachedNetworkImage(imageUrl: product.resolvedThumbnailUrl!, fit: BoxFit.cover)
                    : Container(color: AppColors.divider, child: const Icon(Icons.image, size: 80, color: AppColors.textHint)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                        child: Text(product.categoryName!, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    if (product.weightLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(product.weightLabel!, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (product.hasDiscount) ...[
                          Text('€${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, decoration: TextDecoration.lineThrough, color: AppColors.textHint)),
                          const SizedBox(width: 8),
                          Text('€${product.discountPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.accent)),
                        ] else if (product.hasOffer) ...[
                          Text('€${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                            child: Text('${product.offerLabel} FREE',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                          ),
                        ] else
                          Text('€${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ],
                    ),
                    // Per-unit price line
                    if (product.pricePerUnitText != null) ...[
                      const SizedBox(height: 4),
                      Text(product.pricePerUnitText!,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: product.inStock ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(product.inStock ? 'In Stock' : 'Out of Stock',
                            style: TextStyle(color: product.inStock ? AppColors.success : AppColors.error, fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                        if (product.brandName != null) ...[
                          const SizedBox(width: 10),
                          Text('Brand: ${product.brandName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ],
                    ),
                    if (product.description != null) ...[
                      const SizedBox(height: 20),
                      const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(product.description!, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load product')),
      ),
      bottomSheet: productAsync.whenOrNull(
        data: (product) => product.inStock ? Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)]),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await ref.read(cartProvider.notifier).addToCart(product.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart!'), duration: Duration(seconds: 1)));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      String message = 'Something went wrong';
                      if (e is DioException && e.response?.data != null) {
                        final data = e.response!.data;
                        if (data is Map && data['message'] != null) message = data['message'];
                      }
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error, duration: const Duration(seconds: 2)));
                    }
                  }
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: Text('Add to Cart — €${product.effectivePrice.toStringAsFixed(2)}'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ),
        ) : null,
      ),
    );
  }
}

