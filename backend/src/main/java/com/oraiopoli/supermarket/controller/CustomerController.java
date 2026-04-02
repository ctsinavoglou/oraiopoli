package com.oraiopoli.supermarket.controller;

import com.oraiopoli.supermarket.dto.request.*;
import com.oraiopoli.supermarket.dto.response.*;
import com.oraiopoli.supermarket.entity.Promotion;
import com.oraiopoli.supermarket.entity.User;
import com.oraiopoli.supermarket.service.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/customer")
@RequiredArgsConstructor
@Tag(name = "Customer", description = "Authenticated customer endpoints")
public class CustomerController {

    private final UserService userService;
    private final AddressService addressService;
    private final CartService cartService;
    private final OrderService orderService;
    private final PromotionService promotionService;

    // Profile
    @GetMapping("/profile")
    @Operation(summary = "Get current user profile")
    public ResponseEntity<ApiResponse<UserResponse>> getProfile(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(ApiResponse.success(userService.getProfile(user)));
    }

    @PutMapping("/profile")
    @Operation(summary = "Update user profile")
    public ResponseEntity<ApiResponse<UserResponse>> updateProfile(
            @AuthenticationPrincipal User user,
            @RequestBody UpdateProfileRequest request) {
        return ResponseEntity.ok(ApiResponse.success(userService.updateProfile(user, request)));
    }

    // Addresses
    @GetMapping("/addresses")
    @Operation(summary = "Get user addresses")
    public ResponseEntity<ApiResponse<List<AddressResponse>>> getAddresses(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(ApiResponse.success(addressService.getUserAddresses(user.getId())));
    }

    @PostMapping("/addresses")
    @Operation(summary = "Create new address")
    public ResponseEntity<ApiResponse<AddressResponse>> createAddress(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody AddressRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(addressService.createAddress(user, request)));
    }

    @PutMapping("/addresses/{id}")
    @Operation(summary = "Update address")
    public ResponseEntity<ApiResponse<AddressResponse>> updateAddress(
            @AuthenticationPrincipal User user,
            @PathVariable Long id,
            @Valid @RequestBody AddressRequest request) {
        return ResponseEntity.ok(ApiResponse.success(addressService.updateAddress(user.getId(), id, request)));
    }

    @DeleteMapping("/addresses/{id}")
    @Operation(summary = "Delete address")
    public ResponseEntity<ApiResponse<Void>> deleteAddress(
            @AuthenticationPrincipal User user,
            @PathVariable Long id) {
        addressService.deleteAddress(user.getId(), id);
        return ResponseEntity.ok(ApiResponse.success("Address deleted", null));
    }

    // Cart
    @GetMapping("/cart")
    @Operation(summary = "Get cart")
    public ResponseEntity<ApiResponse<CartResponse>> getCart(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(ApiResponse.success(cartService.getCart(user)));
    }

    @PostMapping("/cart/items")
    @Operation(summary = "Add item to cart")
    public ResponseEntity<ApiResponse<CartResponse>> addToCart(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody CartItemRequest request) {
        return ResponseEntity.ok(ApiResponse.success(cartService.addToCart(user, request)));
    }

    @PutMapping("/cart/items/{itemId}")
    @Operation(summary = "Update cart item quantity")
    public ResponseEntity<ApiResponse<CartResponse>> updateCartItem(
            @AuthenticationPrincipal User user,
            @PathVariable Long itemId,
            @RequestParam int quantity) {
        return ResponseEntity.ok(ApiResponse.success(cartService.updateCartItem(user, itemId, quantity)));
    }

    @DeleteMapping("/cart/items/{itemId}")
    @Operation(summary = "Remove item from cart")
    public ResponseEntity<ApiResponse<CartResponse>> removeFromCart(
            @AuthenticationPrincipal User user,
            @PathVariable Long itemId) {
        return ResponseEntity.ok(ApiResponse.success(cartService.removeFromCart(user, itemId)));
    }

    @DeleteMapping("/cart")
    @Operation(summary = "Clear cart")
    public ResponseEntity<ApiResponse<Void>> clearCart(@AuthenticationPrincipal User user) {
        cartService.clearCart(user);
        return ResponseEntity.ok(ApiResponse.success("Cart cleared", null));
    }

    // Orders
    @PostMapping("/checkout")
    @Operation(summary = "Checkout - place order from cart")
    public ResponseEntity<ApiResponse<OrderResponse>> checkout(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody CheckoutRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Order placed successfully", orderService.checkout(user, request)));
    }

    @GetMapping("/orders")
    @Operation(summary = "Get order history")
    public ResponseEntity<ApiResponse<Page<OrderResponse>>> getOrders(
            @AuthenticationPrincipal User user,
            @PageableDefault(size = 10) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.success(orderService.getCustomerOrders(user.getId(), pageable)));
    }

    @GetMapping("/orders/{id}")
    @Operation(summary = "Get order details")
    public ResponseEntity<ApiResponse<OrderResponse>> getOrder(
            @AuthenticationPrincipal User user,
            @PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(orderService.getCustomerOrderById(user.getId(), id)));
    }

    // Promo code validation
    @PostMapping("/validate-promo")
    @Operation(summary = "Validate a promotion code and preview discount")
    public ResponseEntity<ApiResponse<Map<String, Object>>> validatePromoCode(
            @RequestBody Map<String, String> body) {
        String code = body.get("code");
        BigDecimal orderTotal = new BigDecimal(body.getOrDefault("orderTotal", "0"));
        Promotion promotion = promotionService.validatePromoCode(code, orderTotal);
        BigDecimal discount = promotionService.calculateDiscount(promotion, orderTotal);
        return ResponseEntity.ok(ApiResponse.success(Map.of(
                "valid", true,
                "title", promotion.getTitle(),
                "discountAmount", discount,
                "finalTotal", orderTotal.subtract(discount)
        )));
    }
}

