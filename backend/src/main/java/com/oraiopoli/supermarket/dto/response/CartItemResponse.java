package com.oraiopoli.supermarket.dto.response;

import com.oraiopoli.supermarket.entity.CartItem;
import com.oraiopoli.supermarket.entity.Product;
import com.oraiopoli.supermarket.entity.UnitType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

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
    private int paidQuantity;
    private int freeQuantity;
    private BigDecimal subtotal;
    private int stockQuantity;
    private Integer buyQuantity;
    private Integer getQuantity;
    private String unit;
    private BigDecimal weightQuantity;
    private String weightUnit;
    private Integer maxQuantityPerOrder;

    private static boolean isWithinDateRange(Product product) {
        LocalDateTime now = LocalDateTime.now();
        if (product.getDiscountStartDate() != null && now.isBefore(product.getDiscountStartDate())) return false;
        if (product.getDiscountEndDate() != null && now.isAfter(product.getDiscountEndDate())) return false;
        return true;
    }

    private static boolean isDiscountActive(Product product) {
        return product.getDiscountPrice() != null && isWithinDateRange(product);
    }

    private static boolean isOfferActive(Product product) {
        return product.getBuyQuantity() != null && product.getGetQuantity() != null
                && product.getBuyQuantity() >= 1 && product.getGetQuantity() >= 1
                && isWithinDateRange(product);
    }

    public static CartItemResponse fromEntity(CartItem item) {
        Product product = item.getProduct();
        int totalQty = item.getQuantity();

        BigDecimal effectivePrice = isDiscountActive(product)
                ? product.getDiscountPrice()
                : product.getPrice();

        int stock = product.getInventory() != null
                ? product.getInventory().getQuantity() : 0;

        Integer buyQty = isOfferActive(product) ? product.getBuyQuantity() : null;
        Integer getQty = isOfferActive(product) ? product.getGetQuantity() : null;

        // Calculate paid vs free quantities for buy+get offers
        int paidQty = totalQty;
        int freeQty = 0;
        if (buyQty != null && getQty != null) {
            int groupSize = buyQty + getQty;
            int fullGroups = totalQty / groupSize;
            int remainder = totalQty % groupSize;
            freeQty = fullGroups * getQty;
            // Remainder items beyond buyQty in a partial group are also free
            if (remainder > buyQty) {
                freeQty += remainder - buyQty;
            }
            paidQty = totalQty - freeQty;
        }

        BigDecimal subtotal = effectivePrice.multiply(BigDecimal.valueOf(paidQty));

        return CartItemResponse.builder()
                .id(item.getId())
                .productId(product.getId())
                .productName(product.getName())
                .productThumbnail(product.getThumbnailUrl())
                .originalPrice(product.getPrice())
                .unitPrice(effectivePrice)
                .quantity(totalQty)
                .paidQuantity(paidQty)
                .freeQuantity(freeQty)
                .subtotal(subtotal)
                .stockQuantity(stock)
                .buyQuantity(buyQty)
                .getQuantity(getQty)
                .unit(product.getUnit() != null ? product.getUnit().name() : null)
                .weightQuantity(product.getUnit() == UnitType.WEIGHED ? product.getWeightQuantity() : null)
                .weightUnit(product.getUnit() == UnitType.WEIGHED ? product.getWeightUnit() : null)
                .maxQuantityPerOrder(product.getMaxQuantityPerOrder())
                .build();
    }
}

