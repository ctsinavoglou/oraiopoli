package com.oraiopoli.supermarket.dto.response;

import com.oraiopoli.supermarket.entity.OrderItem;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderItemResponse {
    private Long id;
    private Long productId;
    private String productName;
    private BigDecimal unitPrice;
    private int quantity;
    private int paidQuantity;
    private int freeQuantity;
    private BigDecimal subtotal;
    private String unit;
    private BigDecimal weightQuantity;
    private String weightUnit;

    public static OrderItemResponse fromEntity(OrderItem item) {
        return OrderItemResponse.builder()
                .id(item.getId())
                .productId(item.getProduct().getId())
                .productName(item.getProductName())
                .unitPrice(item.getUnitPrice())
                .quantity(item.getQuantity())
                .paidQuantity(item.getPaidQuantity())
                .freeQuantity(item.getFreeQuantity())
                .subtotal(item.getSubtotal())
                .unit(item.getUnit())
                .weightQuantity(item.getWeightQuantity())
                .weightUnit(item.getWeightUnit())
                .build();
    }
}

