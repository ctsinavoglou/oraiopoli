package com.oraiopoli.supermarket.dto.response;

import com.oraiopoli.supermarket.entity.Order;
import com.oraiopoli.supermarket.entity.OrderStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderResponse {
    private Long id;
    private String orderNumber;
    private OrderStatus status;
    private BigDecimal totalAmount;
    private BigDecimal discountAmount;
    private String promotionCode;
    private BigDecimal deliveryFee;
    private String shippingAddress;
    private String shippingCity;
    private String shippingPostalCode;
    private String contactPhone;
    private String notes;
    private String deliveryTimeSlot;
    private String deliveryMethod;
    private BigDecimal expressDeliveryFee;
    private BigDecimal plasticBagFee;
    private String customerName;
    private String customerEmail;
    private List<OrderItemResponse> items;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static OrderResponse fromEntity(Order order) {
        return OrderResponse.builder()
                .id(order.getId())
                .orderNumber(order.getOrderNumber())
                .status(order.getStatus())
                .totalAmount(order.getTotalAmount())
                .discountAmount(order.getDiscountAmount())
                .promotionCode(order.getPromotionCode())
                .deliveryFee(order.getDeliveryFee())
                .shippingAddress(order.getShippingAddress())
                .shippingCity(order.getShippingCity())
                .shippingPostalCode(order.getShippingPostalCode())
                .contactPhone(order.getContactPhone())
                .notes(order.getNotes())
                .deliveryTimeSlot(order.getDeliveryTimeSlot())
                .deliveryMethod(order.getDeliveryMethod())
                .expressDeliveryFee(order.getExpressDeliveryFee())
                .plasticBagFee(order.getPlasticBagFee())
                .customerName(order.getUser().getFullName())
                .customerEmail(order.getUser().getEmail())
                .items(order.getItems().stream().map(OrderItemResponse::fromEntity).toList())
                .createdAt(order.getCreatedAt())
                .updatedAt(order.getUpdatedAt())
                .build();
    }
}

