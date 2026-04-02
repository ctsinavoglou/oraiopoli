package com.oraiopoli.supermarket.service;

import com.oraiopoli.supermarket.dto.request.CheckoutRequest;
import com.oraiopoli.supermarket.dto.request.UpdateOrderStatusRequest;
import com.oraiopoli.supermarket.dto.response.OrderResponse;
import com.oraiopoli.supermarket.entity.*;
import com.oraiopoli.supermarket.exception.BadRequestException;
import com.oraiopoli.supermarket.exception.ResourceNotFoundException;
import com.oraiopoli.supermarket.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class OrderService {

    private final OrderRepository orderRepository;
    private final CartRepository cartRepository;
    private final AddressRepository addressRepository;
    private final InventoryRepository inventoryRepository;
    private final CartItemRepository cartItemRepository;
    private final PromotionService promotionService;
    private final StoreSettingsService storeSettingsService;

    @Transactional
    public OrderResponse checkout(User user, CheckoutRequest request) {
        Cart cart = cartRepository.findByUserId(user.getId())
                .orElseThrow(() -> new BadRequestException("Cart not found"));

        if (cart.getItems().isEmpty()) {
            throw new BadRequestException("Cart is empty");
        }

        Address address = addressRepository.findByIdAndUserId(request.getAddressId(), user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Address", "id", request.getAddressId()));

        // Create order
        Order order = Order.builder()
                .orderNumber(generateOrderNumber())
                .user(user)
                .status(OrderStatus.PENDING)
                .shippingAddress(address.getAddressLine())
                .shippingCity(address.getCity())
                .shippingPostalCode(address.getPostalCode())
                .contactPhone(user.getPhone())
                .notes(request.getNotes())
                .build();

        BigDecimal totalAmount = BigDecimal.ZERO;

        for (CartItem cartItem : cart.getItems()) {
            Product product = cartItem.getProduct();

            // Check stock
            if (product.getInventory() == null || product.getInventory().getQuantity() < cartItem.getQuantity()) {
                throw new BadRequestException("Insufficient stock for product: " + product.getName());
            }

            BigDecimal effectivePrice = product.getDiscountPrice() != null ? product.getDiscountPrice() : product.getPrice();
            BigDecimal subtotal = effectivePrice.multiply(BigDecimal.valueOf(cartItem.getQuantity()));

            OrderItem orderItem = OrderItem.builder()
                    .order(order)
                    .product(product)
                    .productName(product.getName())
                    .unitPrice(effectivePrice)
                    .quantity(cartItem.getQuantity())
                    .subtotal(subtotal)
                    .build();

            order.getItems().add(orderItem);
            totalAmount = totalAmount.add(subtotal);

            // Deduct inventory
            Inventory inventory = product.getInventory();
            inventory.setQuantity(inventory.getQuantity() - cartItem.getQuantity());
            inventoryRepository.save(inventory);
        }

        // Enforce minimum order amount
        BigDecimal minOrderAmount = new BigDecimal(storeSettingsService.getSettingOrDefault("min_order_amount", "0"));
        if (minOrderAmount.compareTo(BigDecimal.ZERO) > 0 && totalAmount.compareTo(minOrderAmount) < 0) {
            throw new BadRequestException("Minimum order amount is €" + minOrderAmount.toPlainString());
        }

        // Apply promo code discount if provided
        if (request.getPromotionCode() != null && !request.getPromotionCode().isBlank()) {
            Promotion promotion = promotionService.validatePromoCode(request.getPromotionCode(), totalAmount);
            BigDecimal discount = promotionService.calculateDiscount(promotion, totalAmount);
            order.setPromotionCode(request.getPromotionCode());
            order.setDiscountAmount(discount);
            totalAmount = totalAmount.subtract(discount);
        }

        // Calculate delivery fee from store settings
        BigDecimal deliveryFee = new BigDecimal(storeSettingsService.getSettingOrDefault("delivery_fee", "0"));
        BigDecimal freeDeliveryThreshold = new BigDecimal(storeSettingsService.getSettingOrDefault("free_delivery_threshold", "0"));
        if (freeDeliveryThreshold.compareTo(BigDecimal.ZERO) > 0 && totalAmount.compareTo(freeDeliveryThreshold) >= 0) {
            deliveryFee = BigDecimal.ZERO; // Free delivery
        }
        order.setDeliveryFee(deliveryFee);
        totalAmount = totalAmount.add(deliveryFee);

        order.setTotalAmount(totalAmount);
        order = orderRepository.save(order);

        // Clear cart
        cartItemRepository.deleteByCartId(cart.getId());
        cart.getItems().clear();

        return OrderResponse.fromEntity(order);
    }

    public Page<OrderResponse> getCustomerOrders(Long userId, Pageable pageable) {
        return orderRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable)
                .map(OrderResponse::fromEntity);
    }

    public OrderResponse getCustomerOrderById(Long userId, Long orderId) {
        Order order = orderRepository.findByIdAndUserId(orderId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Order", "id", orderId));
        return OrderResponse.fromEntity(order);
    }

    // Admin methods
    public Page<OrderResponse> getAllOrders(OrderStatus status, String search, Pageable pageable) {
        if (status != null && search != null && !search.isBlank()) {
            return orderRepository.findByStatusAndSearch(status, search, pageable)
                    .map(OrderResponse::fromEntity);
        }
        if (status != null) {
            return orderRepository.findByStatusOnly(status, pageable)
                    .map(OrderResponse::fromEntity);
        }
        if (search != null && !search.isBlank()) {
            return orderRepository.findBySearchOnly(search, pageable)
                    .map(OrderResponse::fromEntity);
        }
        return orderRepository.findAllByOrderByCreatedAtDesc(pageable)
                .map(OrderResponse::fromEntity);
    }

    public OrderResponse getOrderById(Long id) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Order", "id", id));
        return OrderResponse.fromEntity(order);
    }

    @Transactional
    public OrderResponse updateOrderStatus(Long id, UpdateOrderStatusRequest request) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Order", "id", id));

        order.setStatus(request.getStatus());
        order = orderRepository.save(order);
        return OrderResponse.fromEntity(order);
    }

    private String generateOrderNumber() {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));
        String uuid = UUID.randomUUID().toString().substring(0, 6).toUpperCase();
        return "ORD-" + timestamp + "-" + uuid;
    }
}

