import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/models.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.read(dioProvider));
});

class CartRepository {
  final Dio _dio;
  CartRepository(this._dio);

  Future<Cart> getCart() async {
    final res = await _dio.get(ApiConstants.customerCart);
    return Cart.fromJson(res.data['data']);
  }

  Future<Cart> addToCart(int productId, {int quantity = 1}) async {
    final res = await _dio.post(ApiConstants.customerCartItems, data: {'productId': productId, 'quantity': quantity});
    return Cart.fromJson(res.data['data']);
  }

  Future<Cart> updateCartItem(int itemId, int quantity) async {
    final res = await _dio.put('${ApiConstants.customerCartItems}/$itemId', queryParameters: {'quantity': quantity});
    return Cart.fromJson(res.data['data']);
  }

  Future<Cart> removeFromCart(int itemId) async {
    final res = await _dio.delete('${ApiConstants.customerCartItems}/$itemId');
    return Cart.fromJson(res.data['data']);
  }

  Future<void> clearCart() async {
    await _dio.delete(ApiConstants.customerCart);
  }
}

