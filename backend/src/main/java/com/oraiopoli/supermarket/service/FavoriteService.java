package com.oraiopoli.supermarket.service;

import com.oraiopoli.supermarket.dto.response.ProductResponse;
import com.oraiopoli.supermarket.entity.Favorite;
import com.oraiopoli.supermarket.entity.Product;
import com.oraiopoli.supermarket.entity.User;
import com.oraiopoli.supermarket.exception.BadRequestException;
import com.oraiopoli.supermarket.exception.ResourceNotFoundException;
import com.oraiopoli.supermarket.repository.FavoriteRepository;
import com.oraiopoli.supermarket.repository.ProductRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class FavoriteService {

    private final FavoriteRepository favoriteRepository;
    private final ProductRepository productRepository;

    public List<ProductResponse> getFavorites(User user) {
        List<Favorite> favorites = favoriteRepository.findByUserIdOrderByCreatedAtDesc(user.getId());
        return favorites.stream()
                .map(f -> ProductResponse.fromEntity(f.getProduct()))
                .toList();
    }

    public Set<Long> getFavoriteProductIds(User user) {
        return new HashSet<>(favoriteRepository.findProductIdsByUserId(user.getId()));
    }

    public boolean isFavorite(User user, Long productId) {
        return favoriteRepository.existsByUserIdAndProductId(user.getId(), productId);
    }

    @Transactional
    public void addFavorite(User user, Long productId) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Product", "id", productId));

        if (!product.isActive()) {
            throw new BadRequestException("Product is not available");
        }

        if (favoriteRepository.existsByUserIdAndProductId(user.getId(), productId)) {
            throw new BadRequestException("Product is already in favorites");
        }

        Favorite favorite = Favorite.builder()
                .user(user)
                .product(product)
                .build();
        favoriteRepository.save(favorite);
    }

    @Transactional
    public void removeFavorite(User user, Long productId) {
        Favorite favorite = favoriteRepository.findByUserIdAndProductId(user.getId(), productId)
                .orElseThrow(() -> new ResourceNotFoundException("Favorite", "productId", productId));
        favoriteRepository.delete(favorite);
    }
}

