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

import java.time.LocalDateTime;

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
        boolean unlimitedStock = product.getInventory().isUnlimited();

        // Check if item already in cart
        var existingItem = cartItemRepository.findByCartIdAndProductId(cart.getId(), product.getId());

        if (existingItem.isPresent()) {
            CartItem item = existingItem.get();
            int rawNew = item.getQuantity() + request.getQuantity();
            int newQuantity = adjustQuantityForOffer(product, rawNew, item.getQuantity());
            if (!unlimitedStock && newQuantity > availableStock) {
                throw new BadRequestException("Only " + availableStock + " available in stock" +
                        (item.getQuantity() > 0 ? " (" + item.getQuantity() + " already in cart)" : ""));
            }
            if (product.getMaxQuantityPerOrder() != null && newQuantity > product.getMaxQuantityPerOrder()) {
                throw new BadRequestException("Maximum " + product.getMaxQuantityPerOrder() + " allowed per order");
            }
            item.setQuantity(newQuantity);
            cartItemRepository.save(item);
        } else {
            int newQuantity = adjustQuantityForOffer(product, request.getQuantity(), 0);
            if (!unlimitedStock && newQuantity > availableStock) {
                throw new BadRequestException("Only " + availableStock + " available in stock");
            }
            if (product.getMaxQuantityPerOrder() != null && newQuantity > product.getMaxQuantityPerOrder()) {
                throw new BadRequestException("Maximum " + product.getMaxQuantityPerOrder() + " allowed per order");
            }
            CartItem item = CartItem.builder()
                    .cart(cart)
                    .product(product)
                    .quantity(newQuantity)
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
            int adjustedQuantity = adjustQuantityForOffer(item.getProduct(), quantity, item.getQuantity());
            boolean isUnlimited = item.getProduct().getInventory() != null && item.getProduct().getInventory().isUnlimited();
            int availableStock = item.getProduct().getInventory() != null
                    ? item.getProduct().getInventory().getQuantity() : 0;
            if (!isUnlimited && adjustedQuantity > availableStock) {
                throw new BadRequestException("Only " + availableStock + " available in stock");
            }
            if (item.getProduct().getMaxQuantityPerOrder() != null && adjustedQuantity > item.getProduct().getMaxQuantityPerOrder()) {
                throw new BadRequestException("Maximum " + item.getProduct().getMaxQuantityPerOrder() + " allowed per order");
            }
            item.setQuantity(adjustedQuantity);
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

    /**
     * Adjusts quantity for buy+get offers.
     *
     * When INCREASING: once the remainder within a group reaches buyQty,
     * snap up to the full group (add the free items).
     * E.g., 1+1: add 1 → snap to 2.  2+1: add 1 → stay 1, add 2 → snap to 3.
     *
     * When DECREASING: no auto-adjustment — let the user go to any quantity.
     * The free-item calculation in CartItemResponse handles partial groups
     * (freeQuantity=0 when below a full group).
     */
    private int adjustQuantityForOffer(Product product, int requestedQuantity, int currentQuantity) {
        if (!isOfferActive(product)) return requestedQuantity;
        if (requestedQuantity <= currentQuantity) return requestedQuantity; // decreasing — no snap

        int buyQty = product.getBuyQuantity();
        int getQty = product.getGetQuantity();
        int groupSize = buyQty + getQty;

        int fullGroups = requestedQuantity / groupSize;
        int remainder = requestedQuantity % groupSize;
        if (remainder >= buyQty) {
            // Bought enough to trigger free items — snap to full group
            return (fullGroups + 1) * groupSize;
        }
        return requestedQuantity;
    }

    private boolean isOfferActive(Product product) {
        if (product.getBuyQuantity() == null || product.getGetQuantity() == null) return false;
        if (product.getBuyQuantity() < 1 || product.getGetQuantity() < 1) return false;
        LocalDateTime now = LocalDateTime.now();
        if (product.getDiscountStartDate() != null && now.isBefore(product.getDiscountStartDate())) return false;
        if (product.getDiscountEndDate() != null && now.isAfter(product.getDiscountEndDate())) return false;
        return true;
    }
}

