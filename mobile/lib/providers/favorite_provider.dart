import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/favorite_repository.dart';

// Provider for favorite product IDs (used for heart icon state across the app)
final favoriteIdsProvider = StateNotifierProvider<FavoriteIdsNotifier, AsyncValue<Set<int>>>((ref) {
  return FavoriteIdsNotifier(ref.read(favoriteRepositoryProvider));
});

class FavoriteIdsNotifier extends StateNotifier<AsyncValue<Set<int>>> {
  final FavoriteRepository _repo;
  FavoriteIdsNotifier(this._repo) : super(const AsyncValue.data({}));

  Future<void> loadFavoriteIds() async {
    state = const AsyncValue.loading();
    try {
      final ids = await _repo.getFavoriteIds();
      state = AsyncValue.data(ids);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleFavorite(int productId) async {
    final currentIds = state.valueOrNull ?? {};
    final isFav = currentIds.contains(productId);

    // Optimistic update
    state = AsyncValue.data(
      isFav ? (Set<int>.from(currentIds)..remove(productId)) : (Set<int>.from(currentIds)..add(productId)),
    );

    try {
      if (isFav) {
        await _repo.removeFavorite(productId);
      } else {
        await _repo.addFavorite(productId);
      }
    } catch (e) {
      // Revert on failure
      state = AsyncValue.data(currentIds);
      rethrow;
    }
  }
}

// Provider for the full favorites list (used on the Favorites screen)
final favoritesListProvider = StateNotifierProvider<FavoritesListNotifier, AsyncValue<List<Product>>>((ref) {
  return FavoritesListNotifier(ref.read(favoriteRepositoryProvider));
});

class FavoritesListNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final FavoriteRepository _repo;
  FavoritesListNotifier(this._repo) : super(const AsyncValue.loading());

  Future<void> loadFavorites() async {
    state = const AsyncValue.loading();
    try {
      final favorites = await _repo.getFavorites();
      state = AsyncValue.data(favorites);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

