import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/models.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository(ref.read(dioProvider));
});

class FavoriteRepository {
  final Dio _dio;
  FavoriteRepository(this._dio);

  Future<List<Product>> getFavorites() async {
    final res = await _dio.get(ApiConstants.customerFavorites);
    final list = res.data['data'] as List;
    return list.map((e) => Product.fromJson(e)).toList();
  }

  Future<Set<int>> getFavoriteIds() async {
    final res = await _dio.get(ApiConstants.customerFavoriteIds);
    final list = res.data['data'] as List;
    return list.map((e) => (e as num).toInt()).toSet();
  }

  Future<void> addFavorite(int productId) async {
    await _dio.post('${ApiConstants.customerFavorites}/$productId');
  }

  Future<void> removeFavorite(int productId) async {
    await _dio.delete('${ApiConstants.customerFavorites}/$productId');
  }
}

