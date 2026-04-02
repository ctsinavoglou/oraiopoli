import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/models.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.read(dioProvider));
});

class ProductRepository {
  final Dio _dio;
  ProductRepository(this._dio);

  Future<List<Product>> getFeaturedProducts({int page = 0, int size = 10}) async {
    final res = await _dio.get(ApiConstants.publicFeatured, queryParameters: {'page': page, 'size': size});
    return (res.data['data']['content'] as List).map((p) => Product.fromJson(p)).toList();
  }

  Future<List<Product>> getProducts({int page = 0, int size = 20}) async {
    final res = await _dio.get(ApiConstants.publicProducts, queryParameters: {'page': page, 'size': size});
    return (res.data['data']['content'] as List).map((p) => Product.fromJson(p)).toList();
  }

  Future<List<Product>> searchProducts(String query, {int page = 0, int size = 20}) async {
    final res = await _dio.get(ApiConstants.publicSearch, queryParameters: {'query': query, 'page': page, 'size': size});
    return (res.data['data']['content'] as List).map((p) => Product.fromJson(p)).toList();
  }

  Future<List<Product>> filterProducts({int? categoryId, int? brandId, double? minPrice, double? maxPrice, int page = 0, int size = 20}) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (categoryId != null) params['categoryId'] = categoryId;
    if (brandId != null) params['brandId'] = brandId;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    final res = await _dio.get(ApiConstants.publicFilter, queryParameters: params);
    return (res.data['data']['content'] as List).map((p) => Product.fromJson(p)).toList();
  }

  Future<Product> getProductBySlug(String slug) async {
    final res = await _dio.get('${ApiConstants.publicProducts}/$slug');
    return Product.fromJson(res.data['data']);
  }

  Future<List<Product>> getProductsByCategory(int categoryId, {int page = 0, int size = 20}) async {
    final res = await _dio.get('${ApiConstants.publicProducts}/category/$categoryId', queryParameters: {'page': page, 'size': size});
    return (res.data['data']['content'] as List).map((p) => Product.fromJson(p)).toList();
  }

  Future<List<Category>> getCategories() async {
    final res = await _dio.get(ApiConstants.publicCategories);
    return (res.data['data'] as List).map((c) => Category.fromJson(c)).toList();
  }

  Future<List<Brand>> getBrands() async {
    final res = await _dio.get(ApiConstants.publicBrands);
    return (res.data['data'] as List).map((b) => Brand.fromJson(b)).toList();
  }

  Future<List<Banner>> getBanners() async {
    final res = await _dio.get(ApiConstants.publicBanners);
    return (res.data['data'] as List).map((b) => Banner.fromJson(b)).toList();
  }

  Future<List<Promotion>> getPromotions() async {
    final res = await _dio.get(ApiConstants.publicPromotions);
    return (res.data['data'] as List).map((p) => Promotion.fromJson(p)).toList();
  }

  Future<Map<String, String>> getStoreInfo() async {
    final res = await _dio.get(ApiConstants.publicStoreInfo);
    return Map<String, String>.from(res.data['data']);
  }
}

