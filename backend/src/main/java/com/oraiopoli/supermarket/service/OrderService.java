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

        // Resolve delivery method (default STANDARD)
        String deliveryMethod = request.getDeliveryMethod() != null ? request.getDeliveryMethod().toUpperCase() : "STANDARD";
        if (!deliveryMethod.equals("STANDARD") && !deliveryMethod.equals("EXPRESS") && !deliveryMethod.equals("PICKUP")) {
            deliveryMethod = "STANDARD";
        }

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
                .deliveryTimeSlot(request.getDeliveryTimeSlot())
                .deliveryMethod(deliveryMethod)
                .build();

        BigDecimal totalAmount = BigDecimal.ZERO;

        for (CartItem cartItem : cart.getItems()) {
            Product product = cartItem.getProduct();

            // Check stock
            if (product.getInventory() == null || (!product.getInventory().isUnlimited() && product.getInventory().getQuantity() < cartItem.getQuantity())) {
                throw new BadRequestException("Insufficient stock for product: " + product.getName());
            }

            BigDecimal effectivePrice = isDiscountActive(product) ? product.getDiscountPrice() : product.getPrice();

            // Calculate paid quantity for buy+get offers
            int totalQty = cartItem.getQuantity();
            int paidQty = totalQty;
            int freeQty = 0;
            if (isOfferActive(product)) {
                int groupSize = product.getBuyQuantity() + product.getGetQuantity();
                int fullGroups = totalQty / groupSize;
                int remainder = totalQty % groupSize;
                freeQty = fullGroups * product.getGetQuantity();
                if (remainder > product.getBuyQuantity()) {
                    freeQty += remainder - product.getBuyQuantity();
                }
                paidQty = totalQty - freeQty;
            }

            BigDecimal subtotal = effectivePrice.multiply(BigDecimal.valueOf(paidQty));

            OrderItem orderItem = OrderItem.builder()
                    .order(order)
                    .product(product)
                    .productName(product.getName())
                    .unitPrice(effectivePrice)
                    .quantity(totalQty)
                    .paidQuantity(paidQty)
                    .freeQuantity(freeQty)
                    .subtotal(subtotal)
                    .unit(product.getUnit() != null ? product.getUnit().name() : null)
                    .weightQuantity(product.getWeightQuantity())
                    .weightUnit(product.getWeightUnit())
                    .build();

            order.getItems().add(orderItem);
            totalAmount = totalAmount.add(subtotal);

            // Deduct inventory (skip if unlimited)
            Inventory inventory = product.getInventory();
            if (!inventory.isUnlimited()) {
                inventory.setQuantity(inventory.getQuantity() - cartItem.getQuantity());
                inventoryRepository.save(inventory);
            }
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

        // Calculate plastic bag fee: rate per €10 of items subtotal
        BigDecimal plasticBagRate = new BigDecimal(storeSettingsService.getSettingOrDefault("plastic_bag_fee_per_10", "0.10"));
        BigDecimal itemsSubtotal = totalAmount; // subtotal after promo discount
        int bagUnits = itemsSubtotal.divideToIntegralValue(BigDecimal.TEN).intValue();
        BigDecimal plasticBagFee = plasticBagRate.multiply(BigDecimal.valueOf(Math.max(bagUnits, 0)));
        order.setPlasticBagFee(plasticBagFee);
        totalAmount = totalAmount.add(plasticBagFee);

        // Calculate delivery fee based on delivery method
        if ("PICKUP".equals(deliveryMethod)) {
            order.setDeliveryFee(BigDecimal.ZERO);
        } else {
            BigDecimal deliveryFee = new BigDecimal(storeSettingsService.getSettingOrDefault("delivery_fee", "0"));
            BigDecimal freeDeliveryThreshold = new BigDecimal(storeSettingsService.getSettingOrDefault("free_delivery_threshold", "0"));
            if (freeDeliveryThreshold.compareTo(BigDecimal.ZERO) > 0 && totalAmount.compareTo(freeDeliveryThreshold) >= 0) {
                deliveryFee = BigDecimal.ZERO; // Free delivery
            }
            order.setDeliveryFee(deliveryFee);
            totalAmount = totalAmount.add(deliveryFee);
        }

        // Express delivery surcharge
        if ("EXPRESS".equals(deliveryMethod)) {
            BigDecimal expressFee = new BigDecimal(storeSettingsService.getSettingOrDefault("express_delivery_fee", "1.00"));
            order.setExpressDeliveryFee(expressFee);
            totalAmount = totalAmount.add(expressFee);
        }

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

    private boolean isDiscountActive(Product product) {
        if (product.getDiscountPrice() == null) return false;
        LocalDateTime now = LocalDateTime.now();
        if (product.getDiscountStartDate() != null && now.isBefore(product.getDiscountStartDate())) return false;
        if (product.getDiscountEndDate() != null && now.isAfter(product.getDiscountEndDate())) return false;
        return true;
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

