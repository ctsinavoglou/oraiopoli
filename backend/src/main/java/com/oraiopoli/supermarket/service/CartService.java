package com.oraiopoli.supermarket.service;

import com.oraiopoli.supermarket.dto.request.CartItemRequest;
import com.oraiopoli.supermarket.dto.response.CartResponse;
import com.oraiopoli.supermarket.entity.*;
import com.oraiopoli.supermarket.exception.BadRequestException;
import com.oraiopoli.supermarket.exception.ResourceNotFoundException;
import com.oraiopoli.supermarket.repository.CartItemRepository;
import com.oraiopoli.supermarket.repository.CartRepository;
import com.oraiopoli.supermarket.repository.ProductRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CartService {

    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;
    private final ProductRepository productRepository;

    @Transactional(readOnly = true)
    public CartResponse getCart(User user) {
        Cart cart = getOrCreateCart(user);
        return CartResponse.fromEntity(cart);
    }

    @Transactional
    public CartResponse addToCart(User user, CartItemRequest request) {
        Cart cart = getOrCreateCart(user);

        Product product = productRepository.findById(request.getProductId())
                .orElseThrow(() -> new ResourceNotFoundException("Product", "id", request.getProductId()));

        if (!product.isActive()) {
            throw new BadRequestException("Product is not available");
        }

        if (product.getInventory() == null || !product.getInventory().isInStock()) {
            throw new BadRequestException("Product is out of stock");
        }

        int availableStock = product.getInventory().getQuantity();

        // Check if item already in cart
        var existingItem = cartItemRepository.findByCartIdAndProductId(cart.getId(), product.getId());

        if (existingItem.isPresent()) {
            CartItem item = existingItem.get();
            int newQuantity = item.getQuantity() + request.getQuantity();
            if (newQuantity > availableStock) {
                throw new BadRequestException("Only " + availableStock + " available in stock" +
                        (item.getQuantity() > 0 ? " (" + item.getQuantity() + " already in cart)" : ""));
            }
            item.setQuantity(newQuantity);
            cartItemRepository.save(item);
        } else {
            if (request.getQuantity() > availableStock) {
                throw new BadRequestException("Only " + availableStock + " available in stock");
            }
            CartItem item = CartItem.builder()
                    .cart(cart)
                    .product(product)
                    .quantity(request.getQuantity())
                    .build();
            cartItemRepository.save(item);
            cart.getItems().add(item);
        }

        cart = cartRepository.findByUserId(user.getId()).orElseThrow();
        return CartResponse.fromEntity(cart);
    }

    @Transactional
    public CartResponse updateCartItem(User user, Long itemId, int quantity) {
        Cart cart = getOrCreateCart(user);

        CartItem item = cartItemRepository.findById(itemId)
                .orElseThrow(() -> new ResourceNotFoundException("Cart item", "id", itemId));

        if (!item.getCart().getId().equals(cart.getId())) {
            throw new BadRequestException("Cart item does not belong to your cart");
        }

        if (quantity <= 0) {
            cartItemRepository.delete(item);
            cart.getItems().remove(item);
        } else {
            int availableStock = item.getProduct().getInventory() != null
                    ? item.getProduct().getInventory().getQuantity() : 0;
            if (quantity > availableStock) {
                throw new BadRequestException("Only " + availableStock + " available in stock");
            }
            item.setQuantity(quantity);
            cartItemRepository.save(item);
        }

        cart = cartRepository.findByUserId(user.getId()).orElseThrow();
        return CartResponse.fromEntity(cart);
    }

    @Transactional
    public CartResponse removeFromCart(User user, Long itemId) {
        Cart cart = getOrCreateCart(user);

        CartItem item = cartItemRepository.findById(itemId)
                .orElseThrow(() -> new ResourceNotFoundException("Cart item", "id", itemId));

        if (!item.getCart().getId().equals(cart.getId())) {
            throw new BadRequestException("Cart item does not belong to your cart");
        }

        cartItemRepository.delete(item);
        cart.getItems().remove(item);

        cart = cartRepository.findByUserId(user.getId()).orElseThrow();
        return CartResponse.fromEntity(cart);
    }

    @Transactional
    public void clearCart(User user) {
        Cart cart = getOrCreateCart(user);
        cartItemRepository.deleteByCartId(cart.getId());
        cart.getItems().clear();
    }

    private Cart getOrCreateCart(User user) {
        return cartRepository.findByUserId(user.getId())
                .orElseGet(() -> {
                    Cart cart = Cart.builder().user(user).build();
                    return cartRepository.save(cart);
                });
    }
}

