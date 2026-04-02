import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../widgets/product_card.dart';

/// Shows a category detail: subcategories (if any) at the top,
/// then the category's own products below.
class CategoryDetailScreen extends ConsumerWidget {
  final int categoryId;

  const CategoryDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve category from the already-loaded tree
    final categoriesAsync = ref.watch(categoriesProvider);
    final products = ref.watch(categoryProductsProvider(categoryId));
    final favoriteIds = ref.watch(favoriteIdsProvider).valueOrNull ?? {};

    return categoriesAsync.when(
      data: (rootCategories) {
        final category = _findCategory(rootCategories, categoryId);
        final title = category?.name ?? 'Category';
        final children = category?.children ?? [];
        final breadcrumb = _buildPath(rootCategories, categoryId);

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: CustomScrollView(
            slivers: [
              // ── Breadcrumb navigation (shown when deeper than first level) ──
              if (breadcrumb.length > 1)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int b = 0; b < breadcrumb.length; b++) ...[
                            if (b > 0) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.chevron_right,
                                    size: 16, color: AppColors.textHint),
                              ),
                            ],
                            if (b < breadcrumb.length - 1)
                              GestureDetector(
                                onTap: () {
                                  // Navigate back to ancestor category
                                  if (b == 0) {
                                    context.go('/categories');
                                  } else {
                                    context.go('/category/${breadcrumb[b].id}');
                                  }
                                },
                                child: Text(
                                  breadcrumb[b].name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            else
                              Text(
                                breadcrumb[b].name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Subcategories section ──
              if (children.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_open,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Subcategories',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: children.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final sub = children[i];
                        return GestureDetector(
                          onTap: () {
                            context.push('/category/${sub.id}');
                          },
                          child: SizedBox(
                            width: 90,
                            child: Column(
                              children: [
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.2)),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: sub.imageUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: sub.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) =>
                                              const Icon(Icons.category,
                                                  color: AppColors.primary),
                                        )
                                      : const Icon(Icons.category,
                                          color: AppColors.primary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  sub.name,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Divider(height: 24, indent: 16, endIndent: 16),
                ),
              ],

              // ── Products section header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Products',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Products grid ──
              products.when(
                data: (list) => list.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('No products in this category',
                                style: TextStyle(color: AppColors.textHint)),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => ProductCard(
                              product: list[i],
                              onTap: () =>
                                  context.push('/products/${list[i].slug}'),
                              isFavorite: favoriteIds.contains(list[i].id),
                              onToggleFavorite: () => ref.read(favoriteIdsProvider.notifier).toggleFavorite(list[i].id),
                              onAddToCart: () async {
                                try {
                                  await ref
                                      .read(cartProvider.notifier)
                                      .addToCart(list[i].id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Added to cart!'),
                                          duration: Duration(seconds: 1)),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    String message = 'Something went wrong';
                                    if (e is DioException &&
                                        e.response?.data != null) {
                                      final data = e.response!.data;
                                      if (data is Map &&
                                          data['message'] != null) {
                                        message = data['message'];
                                      }
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(message),
                                          backgroundColor: AppColors.error,
                                          duration:
                                              const Duration(seconds: 2)),
                                    );
                                  }
                                }
                              },
                            ),
                            childCount: list.length,
                          ),
                        ),
                      ),
                loading: () => const SliverToBoxAdapter(
                  child: SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator())),
                ),
                error: (_, __) => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Failed to load products')),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Category')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Category')),
        body: const Center(child: Text('Failed to load category')),
      ),
    );
  }

  /// Recursively search the category tree for a given id
  Category? _findCategory(List<Category> categories, int id) {
    for (final cat in categories) {
      if (cat.id == id) return cat;
      if (cat.children != null) {
        final found = _findCategory(cat.children!, id);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Build the full path from root to the category with [id].
  /// Returns a list like [RootCat, SubCat, SubSubCat, CurrentCat].
  List<Category> _buildPath(List<Category> categories, int id) {
    for (final cat in categories) {
      if (cat.id == id) return [cat];
      if (cat.children != null) {
        final childPath = _buildPath(cat.children!, id);
        if (childPath.isNotEmpty) return [cat, ...childPath];
      }
    }
    return [];
  }
}

