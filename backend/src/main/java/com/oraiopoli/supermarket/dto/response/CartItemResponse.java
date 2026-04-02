package com.oraiopoli.supermarket.dto.response;

import com.oraiopoli.supermarket.entity.CartItem;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CartItemResponse {
    private Long id;
    private Long productId;
    private String productName;
    private String productThumbnail;
    private BigDecimal originalPrice;
    private BigDecimal unitPrice;
    private int quantity;
    private BigDecimal subtotal;
    private int stockQuantity;

    public static CartItemResponse fromEntity(CartItem item) {
        BigDecimal effectivePrice = item.getProduct().getDiscountPrice() != null
                ? item.getProduct().getDiscountPrice()
                : item.getProduct().getPrice();

        int stock = item.getProduct().getInventory() != null
                ? item.getProduct().getInventory().getQuantity() : 0;

        return CartItemResponse.builder()
                .id(item.getId())
                .productId(item.getProduct().getId())
                .productName(item.getProduct().getName())
                .productThumbnail(item.getProduct().getThumbnailUrl())
                .originalPrice(item.getProduct().getPrice())
                .unitPrice(effectivePrice)
                .quantity(item.getQuantity())
                .subtotal(effectivePrice.multiply(BigDecimal.valueOf(item.getQuantity())))
                .stockQuantity(stock)
                .build();
    }
}

