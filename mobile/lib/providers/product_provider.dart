import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/product_repository.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.read(productRepositoryProvider).getCategories();
});

final featuredProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  return ref.read(productRepositoryProvider).getFeaturedProducts();
});

final bannersProvider = FutureProvider<List<Banner>>((ref) {
  return ref.read(productRepositoryProvider).getBanners();
});

final productsProvider = FutureProvider.family<List<Product>, int>((ref, page) {
  return ref.read(productRepositoryProvider).getProducts(page: page);
});

final categoryProductsProvider = FutureProvider.autoDispose.family<List<Product>, int>((ref, categoryId) {
  return ref.read(productRepositoryProvider).getProductsByCategory(categoryId);
});

final productDetailProvider = FutureProvider.autoDispose.family<Product, String>((ref, slug) {
  return ref.read(productRepositoryProvider).getProductBySlug(slug);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Product>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.length < 3) return Future.value([]);
  return ref.read(productRepositoryProvider).searchProducts(query);
});

final storeInfoProvider = FutureProvider<Map<String, String>>((ref) {
  return ref.read(productRepositoryProvider).getStoreInfo();
});

