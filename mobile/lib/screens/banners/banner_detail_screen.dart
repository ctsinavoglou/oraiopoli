import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:dio/dio.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../widgets/product_card.dart';

class BannerDetailScreen extends ConsumerWidget {
  final int bannerId;
  const BannerDetailScreen({super.key, required this.bannerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannerAsync = ref.watch(bannerDetailProvider(bannerId));
    final favoriteIds = ref.watch(favoriteIdsProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: AppBar(
        title: bannerAsync.whenOrNull(data: (b) => Text(b.title)) ?? const Text(''),
      ),
      body: bannerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
              const SizedBox(height: 12),
              const Text('Failed to load banner', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(bannerDetailProvider(bannerId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (banner) {
          final hasContent = banner.contentBody != null && banner.contentBody!.isNotEmpty;
          final hasProducts = banner.products != null && banner.products!.isNotEmpty;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner image
                SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: CachedNetworkImage(
                    imageUrl: banner.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.divider,
                      child: const Center(child: Icon(Icons.image_not_supported, size: 48, color: AppColors.textHint)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      if (banner.subtitle != null && banner.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          banner.subtitle!,
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                      if (hasContent) ...[
                        const SizedBox(height: 16),
                        MarkdownBody(
                          data: banner.contentBody!,
                          styleSheet: MarkdownStyleSheet(
                            h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                            h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            p: const TextStyle(fontSize: 14, height: 1.5),
                            listBullet: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Products grid
                if (hasProducts) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Text('Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: Responsive.gridDelegate(context),
                    itemCount: banner.products!.length,
                    itemBuilder: (_, i) {
                      final product = banner.products![i];
                      return ProductCard(
                        product: product,
                        onTap: () => context.push('/products/${product.slug}'),
                        isFavorite: favoriteIds.contains(product.id),
                        onToggleFavorite: () => ref.read(favoriteIdsProvider.notifier).toggleFavorite(product.id),
                        onAddToCart: () async {
                          try {
                            await ref.read(cartProvider.notifier).addToCart(product.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Added to cart!'), duration: Duration(seconds: 1)),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              String msg = 'Something went wrong';
                              if (e is DioException && e.response?.data is Map) {
                                msg = (e.response!.data as Map)['message'] ?? msg;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg), backgroundColor: AppColors.error, duration: const Duration(seconds: 2)),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

