package com.oraiopoli.supermarket.dto.response;

import com.oraiopoli.supermarket.entity.Cart;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.Comparator;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CartResponse {
    private Long id;
    private List<CartItemResponse> items;
    private BigDecimal totalAmount;
    private int totalItems;

    public static CartResponse fromEntity(Cart cart) {
        List<CartItemResponse> itemResponses = cart.getItems().stream()
                .sorted(Comparator.comparing(item -> item.getId()))
                .map(CartItemResponse::fromEntity)
                .toList();

        BigDecimal total = itemResponses.stream()
                .map(CartItemResponse::getSubtotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return CartResponse.builder()
                .id(cart.getId())
                .items(itemResponses)
                .totalAmount(total)
                .totalItems(itemResponses.stream().mapToInt(CartItemResponse::getQuantity).sum())
                .build();
    }
}

