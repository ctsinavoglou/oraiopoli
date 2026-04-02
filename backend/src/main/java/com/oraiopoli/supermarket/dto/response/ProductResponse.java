package com.oraiopoli.supermarket.dto.response;

import com.oraiopoli.supermarket.entity.Product;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
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

    public static ProductResponse fromEntity(Product product) {
        return ProductResponse.builder()
                .id(product.getId())
                .name(product.getName())
                .slug(product.getSlug())
                .sku(product.getSku())
                .description(product.getDescription())
                .price(product.getPrice())
                .discountPrice(product.getDiscountPrice())
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
                .discountPrice(product.getDiscountPrice())
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
}

