import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/cart_repository.dart';

final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<Cart?>>((ref) {
  return CartNotifier(ref.read(cartRepositoryProvider));
});

class CartNotifier extends StateNotifier<AsyncValue<Cart?>> {
  final CartRepository _repo;
  CartNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> loadCart() async {
    state = const AsyncValue.loading();
    try {
      final cart = await _repo.getCart();
      state = AsyncValue.data(cart);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addToCart(int productId, {int quantity = 1}) async {
    try {
      final cart = await _repo.addToCart(productId, quantity: quantity);
      state = AsyncValue.data(cart);
    } catch (e) {
      rethrow; // Let UI handle the error message
    }
  }

  Future<void> updateItem(int itemId, int quantity) async {
    try {
      final cart = await _repo.updateCartItem(itemId, quantity);
      state = AsyncValue.data(cart);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeItem(int itemId) async {
    try {
      final cart = await _repo.removeFromCart(itemId);
      state = AsyncValue.data(cart);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clear() async {
    try {
      await _repo.clearCart();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

