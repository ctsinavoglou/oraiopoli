package com.oraiopoli.supermarket.dto.response;

import com.oraiopoli.supermarket.entity.Product;
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
public class ProductResponse {
    private Long id;
    private String name;
    private String slug;
    private String sku;
    private String description;
    private BigDecimal price;
    private BigDecimal discountPrice;
    private LocalDateTime discountStartDate;
    private LocalDateTime discountEndDate;
    private Integer buyQuantity;
    private Integer getQuantity;
    private String unit;
    private boolean active;
    private boolean featured;
    private String thumbnailUrl;
    private String categoryName;
    private Long categoryId;
    private String brandName;
    private Long brandId;
    private int stockQuantity;
    private boolean inStock;
    private List<ProductImageResponse> images;

    /**
     * Checks whether the discount is currently active based on date range.
     * If no dates are set, the discount is always active (backwards compatible).
     */
    private static boolean isDiscountActive(Product product) {
        if (product.getDiscountPrice() == null) return false;
        return isWithinDateRange(product);
    }

    /**
     * Checks whether the buy+get offer is currently active based on date range.
     */
    private static boolean isOfferActive(Product product) {
        if (product.getBuyQuantity() == null || product.getGetQuantity() == null) return false;
        if (product.getBuyQuantity() < 1 || product.getGetQuantity() < 1) return false;
        return isWithinDateRange(product);
    }

    private static boolean isWithinDateRange(Product product) {
        LocalDateTime now = LocalDateTime.now();
        if (product.getDiscountStartDate() != null && now.isBefore(product.getDiscountStartDate())) return false;
        if (product.getDiscountEndDate() != null && now.isAfter(product.getDiscountEndDate())) return false;
        return true;
    }

    public static ProductResponse fromEntity(Product product) {
        return ProductResponse.builder()
                .id(product.getId())
                .name(product.getName())
                .slug(product.getSlug())
                .sku(product.getSku())
                .description(product.getDescription())
                .price(product.getPrice())
                .discountPrice(isDiscountActive(product) ? product.getDiscountPrice() : null)
                .discountStartDate(product.getDiscountStartDate())
                .discountEndDate(product.getDiscountEndDate())
                .buyQuantity(isOfferActive(product) ? product.getBuyQuantity() : null)
                .getQuantity(isOfferActive(product) ? product.getGetQuantity() : null)
                .unit(product.getUnit())
                .active(product.isActive())
                .featured(product.isFeatured())
                .thumbnailUrl(product.getThumbnailUrl())
                .categoryName(product.getCategory() != null ? product.getCategory().getName() : null)
                .categoryId(product.getCategory() != null ? product.getCategory().getId() : null)
                .brandName(product.getBrand() != null ? product.getBrand().getName() : null)
                .brandId(product.getBrand() != null ? product.getBrand().getId() : null)
                .stockQuantity(product.getInventory() != null ? product.getInventory().getQuantity() : 0)
                .inStock(product.getInventory() != null && product.getInventory().isInStock())
                .images(product.getImages() != null
                        ? product.getImages().stream().map(ProductImageResponse::fromEntity).toList()
                        : null)
                .build();
    }

    public static ProductResponse fromEntityLightweight(Product product) {
        return ProductResponse.builder()
                .id(product.getId())
                .name(product.getName())
                .slug(product.getSlug())
                .price(product.getPrice())
                .discountPrice(isDiscountActive(product) ? product.getDiscountPrice() : null)
                .buyQuantity(isOfferActive(product) ? product.getBuyQuantity() : null)
                .getQuantity(isOfferActive(product) ? product.getGetQuantity() : null)
                .unit(product.getUnit())
                .featured(product.isFeatured())
                .thumbnailUrl(product.getThumbnailUrl())
                .categoryName(product.getCategory() != null ? product.getCategory().getName() : null)
                .categoryId(product.getCategory() != null ? product.getCategory().getId() : null)
                .brandName(product.getBrand() != null ? product.getBrand().getName() : null)
                .stockQuantity(product.getInventory() != null ? product.getInventory().getQuantity() : 0)
                .inStock(product.getInventory() != null && product.getInventory().isInStock())
                .build();
    }

    /**
     * Admin variant — always includes the raw discountPrice regardless of date range,
     * so the admin can see and edit scheduled discounts.
     */
    public static ProductResponse fromEntityAdmin(Product product) {
        return ProductResponse.builder()
                .id(product.getId())
                .name(product.getName())
                .slug(product.getSlug())
                .sku(product.getSku())
                .description(product.getDescription())
                .price(product.getPrice())
                .discountPrice(product.getDiscountPrice())
                .discountStartDate(product.getDiscountStartDate())
                .discountEndDate(product.getDiscountEndDate())
                .buyQuantity(product.getBuyQuantity())
                .getQuantity(product.getGetQuantity())
                .unit(product.getUnit())
                .active(product.isActive())
                .featured(product.isFeatured())
                .thumbnailUrl(product.getThumbnailUrl())
                .categoryName(product.getCategory() != null ? product.getCategory().getName() : null)
                .categoryId(product.getCategory() != null ? product.getCategory().getId() : null)
                .brandName(product.getBrand() != null ? product.getBrand().getName() : null)
                .brandId(product.getBrand() != null ? product.getBrand().getId() : null)
                .stockQuantity(product.getInventory() != null ? product.getInventory().getQuantity() : 0)
                .inStock(product.getInventory() != null && product.getInventory().isInStock())
                .images(product.getImages() != null
                        ? product.getImages().stream().map(ProductImageResponse::fromEntity).toList()
                        : null)
                .build();
    }
}

