import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart' as models;
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _bannerController = PageController();
  int _currentBannerPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final banners = ref.read(bannersProvider).valueOrNull;
      if (banners != null && banners.isNotEmpty && _bannerController.hasClients) {
        final nextPage = (_currentBannerPage + 1) % banners.length;
        _bannerController.animateToPage(nextPage,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      }
    });
  }

  void _onBannerTap(models.Banner banner, BuildContext context) {
    if (banner.linkUrl != null && banner.linkUrl!.isNotEmpty) {
      context.push(banner.linkUrl!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final banners = ref.watch(bannersProvider);
    final featured = ref.watch(featuredProductsProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 32, height: 32),
            const SizedBox(width: 8),
            const Text('Oraiopoli', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {
            showSearch(context: context, delegate: _ProductSearchDelegate(ref));
          }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bannersProvider);
          ref.invalidate(featuredProductsProvider);
          ref.invalidate(categoriesProvider);
        },
        child: ListView(
          children: [
            // Banner carousel
            banners.when(
              data: (list) => list.isEmpty ? const SizedBox.shrink() : Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: PageView.builder(
                      controller: _bannerController,
                      itemCount: list.length,
                      onPageChanged: (i) => setState(() => _currentBannerPage = i),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _onBannerTap(list[i], context),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: AppColors.primaryLight),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(imageUrl: list[i].imageUrl, fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported, size: 48, color: AppColors.textHint))),
                              // Gradient overlay for text readability
                              Positioned(
                                left: 0, right: 0, bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(list[i].title,
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                      if (list[i].subtitle != null && list[i].subtitle!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(list[i].subtitle!,
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Page indicator dots
                  if (list.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(list.length, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentBannerPage == i ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentBannerPage == i ? AppColors.primary : AppColors.border,
                          ),
                        )),
                      ),
                    ),
                ],
              ),
              loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Categories
            _sectionHeader(context, 'Categories', () => context.go('/categories')),
            categories.when(
              data: (list) => SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final cat = list[i];
                    return GestureDetector(
                      onTap: () {
                        if (cat.children != null && cat.children!.isNotEmpty) {
                          context.push('/category/${cat.id}');
                        } else {
                          context.push('/products/category/${cat.id}?title=${cat.name}');
                        }
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
                            child: cat.imageUrl != null
                                ? ClipRRect(borderRadius: BorderRadius.circular(16),
                                    child: CachedNetworkImage(imageUrl: cat.imageUrl!, fit: BoxFit.cover))
                                : const Icon(Icons.category, color: AppColors.primary),
                          ),
                          const SizedBox(height: 6),
                          Text(cat.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    );
                  },
                ),
              ),
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Featured products
            _sectionHeader(context, 'Featured Products', null),
            featured.when(
              data: (list) => list.isEmpty
                  ? const Padding(padding: EdgeInsets.all(20), child: Text('No featured products', textAlign: TextAlign.center))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, childAspectRatio: 0.68, crossAxisSpacing: 12, mainAxisSpacing: 12,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, i) => ProductCard(
                        product: list[i],
                        onTap: () => context.push('/products/${list[i].slug}'),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(_parseError(e)), backgroundColor: AppColors.error, duration: const Duration(seconds: 2)),
                              );
                            }
                          }
                        },
                      ),
                    ),
              loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const Padding(padding: EdgeInsets.all(20), child: Text('Failed to load products')),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, VoidCallback? onSeeAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          if (onSeeAll != null)
            GestureDetector(onTap: onSeeAll, child: const Text('See All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  String _parseError(Object e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) return data['message'];
    }
    return 'Something went wrong';
  }
}

class _ProductSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;
  _ProductSearchDelegate(this.ref);

  @override List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty) IconButton(icon: const Icon(Icons.clear), onPressed: () { query = ''; showSuggestions(context); }),
  ];
  @override Widget buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 3) {
      return const Center(child: Text('Type at least 3 characters to search'));
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final currentQuery = query;
    if (currentQuery.length < 3) {
      return const Center(child: Text('Type at least 3 characters to search'));
    }
    Future(() => ref.read(searchQueryProvider.notifier).state = currentQuery);
    return Consumer(builder: (context, ref, _) {
      final results = ref.watch(searchResultsProvider);
      return results.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('No results found'))
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.68, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: list.length,
                itemBuilder: (_, i) => ProductCard(product: list[i], onTap: () {
                  close(context, '');
                  context.push('/products/${list[i].slug}');
                }),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Search failed')),
      );
    });
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = super.appBarTheme(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
      ),
    );
  }
}

